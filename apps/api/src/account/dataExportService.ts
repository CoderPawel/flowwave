import { Inject, Injectable, Logger } from '@nestjs/common';
import { ConflictError, NotFoundError } from '@flowwave/core';
import type { Prisma } from '../../generated/prisma/client.js';
import type { ExportJobStatus } from '../../generated/prisma/enums.js';
import { AuditService } from '../audit/auditService.js';
import { addDays, CLOCK, type Clock } from '../common/clock.js';
import { PrismaService } from '../prisma/prismaService.js';
import { RateLimiter } from '../rateLimit/rateLimiter.js';

export const EXPORT_FORMAT = 'flowwave-account-export';
export const EXPORT_FORMAT_VERSION = 1;
export const EXPORT_RETENTION_DAYS = 7;

/**
 * Every table holding the user's rows, exported with its database column names.
 * A test checks that every table with a `user_id` column is listed here.
 */
export const EXPORTED_TABLES = [
  'users',
  'user_credentials',
  'devices',
  'auth_sessions',
  'auth_tokens',
  'consent_decisions',
  'health_data_sources',
  'health_samples',
  'sleep_sessions',
  'activity_sessions',
  'device_usage_buckets',
  'check_ins',
  'meal_events',
  'caffeine_events',
  'rest_events',
  'focus_sessions',
  'daily_scores',
  'rhythm_buckets',
  'recommendations',
  'sync_checkpoints',
  'applied_sync_operations',
  'data_export_jobs',
  'audit_events',
] as const;

/** Secrets and nested exports are left out; the file says so. */
export const OMITTED_COLUMNS: Readonly<Partial<Record<(typeof EXPORTED_TABLES)[number], readonly string[]>>> = {
  user_credentials: ['password_hash'],
  auth_tokens: ['access_token_hash', 'refresh_token_hash'],
  data_export_jobs: ['result'],
};

export const EXPORT_NOTICE =
  'This file contains your FlowWave data, including health data. Keep it private. ' +
  'Scores and recommendations in it are estimates for self-observation, not medical diagnoses.';

export interface ExportJobView {
  readonly id: string;
  readonly status: ExportJobStatus;
  readonly requestedAt: Date;
  readonly completedAt: Date | null;
  readonly expiresAt: Date | null;
  readonly failureCode: string | null;
  readonly resultBytes: number | null;
}

const JOB_SELECT = {
  id: true,
  status: true,
  requestedAtUtc: true,
  completedAtUtc: true,
  expiresAtUtc: true,
  failureCode: true,
  resultBytes: true,
} as const;

function toView(job: {
  id: string;
  status: ExportJobStatus;
  requestedAtUtc: Date;
  completedAtUtc: Date | null;
  expiresAtUtc: Date | null;
  failureCode: string | null;
  resultBytes: number | null;
}): ExportJobView {
  return {
    id: job.id,
    status: job.status,
    requestedAt: job.requestedAtUtc,
    completedAt: job.completedAtUtc,
    expiresAt: job.expiresAtUtc,
    failureCode: job.failureCode,
    resultBytes: job.resultBytes,
  };
}

/** Makes raw query values JSON-safe: instants as ISO 8601 UTC, 64-bit integers as strings. */
function jsonValue(value: unknown): Prisma.JsonValue {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'bigint') return value.toString();
  if (Array.isArray(value)) return value.map(jsonValue);
  if (typeof value === 'object') {
    if (typeof (value as { toJSON?: unknown }).toJSON === 'function') {
      return (value as { toJSON(): Prisma.JsonValue }).toJSON();
    }
    return Object.fromEntries(Object.entries(value).map(([key, inner]) => [key, jsonValue(inner)]));
  }
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') return value;
  throw new TypeError(`Unsupported column value of type ${typeof value}.`);
}

@Injectable()
export class DataExportService {
  private readonly logger = new Logger(DataExportService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly limiter: RateLimiter,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Queues an export, or returns the one already queued or running. */
  async request(userId: string): Promise<{ job: ExportJobView; created: boolean }> {
    return this.prisma.$transaction(async (tx) => {
      // Serializes concurrent requests of one user so at most one job is open.
      await tx.$queryRaw`SELECT id FROM users WHERE id = ${userId}::uuid FOR UPDATE`;
      const open = await tx.dataExportJob.findFirst({
        where: { userId, status: { in: ['pending', 'running'] } },
        select: JOB_SELECT,
        orderBy: { requestedAtUtc: 'asc' },
      });
      if (open) return { job: toView(open), created: false };
      this.limiter.consume('account.export', `user:${userId}`);
      const job = await tx.dataExportJob.create({
        data: { userId, requestedAtUtc: this.clock.now() },
        select: JOB_SELECT,
      });
      await this.audit.record(
        { userId, action: 'data_export_requested', entity: { type: 'data_export_job', id: job.id } },
        tx,
      );
      return { job: toView(job), created: true };
    });
  }

  async get(userId: string, jobId: string): Promise<ExportJobView> {
    const job = await this.prisma.dataExportJob.findFirst({ where: { id: jobId, userId }, select: JOB_SELECT });
    if (!job) throw new NotFoundError('Export');
    return toView(job);
  }

  async download(userId: string, jobId: string): Promise<Prisma.JsonObject> {
    const job = await this.prisma.dataExportJob.findFirst({
      where: { id: jobId, userId },
      select: { id: true, status: true, expiresAtUtc: true, result: true },
    });
    if (!job) throw new NotFoundError('Export');
    if (job.status === 'expired' || (job.expiresAtUtc !== null && job.expiresAtUtc <= this.clock.now())) {
      throw new ConflictError('status', 'This export has expired; request a new one.');
    }
    if (job.status !== 'completed' || job.result === null || typeof job.result !== 'object' || Array.isArray(job.result)) {
      throw new ConflictError('status', 'This export is not ready yet.');
    }
    return job.result;
  }

  /** Processes up to `limit` queued jobs, oldest first. Safe to run in several processes at once. */
  async processPending(limit = 5): Promise<number> {
    let processed = 0;
    while (processed < limit) {
      const next = await this.prisma.dataExportJob.findFirst({
        where: { status: 'pending' },
        select: { id: true, userId: true },
        orderBy: { requestedAtUtc: 'asc' },
      });
      if (!next) break;
      const claimed = await this.prisma.dataExportJob.updateMany({
        where: { id: next.id, status: 'pending' },
        data: { status: 'running', startedAtUtc: this.clock.now() },
      });
      if (claimed.count !== 1) continue;
      await this.run(next.id, next.userId);
      processed += 1;
    }
    return processed;
  }

  async build(userId: string): Promise<Prisma.JsonObject> {
    const tables: Record<string, Prisma.JsonValue> = {};
    for (const table of EXPORTED_TABLES) {
      const key = table === 'users' ? 'id' : 'user_id';
      // Table and column names come from the constant list above, never from input.
      const rows = await this.prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT * FROM "${table}" WHERE "${key}" = $1::uuid ORDER BY 1`,
        userId,
      );
      const omitted = OMITTED_COLUMNS[table] ?? [];
      tables[table] = rows.map((row) =>
        Object.fromEntries(
          Object.entries(row)
            .filter(([column]) => !omitted.includes(column))
            .map(([column, value]) => [column, jsonValue(value)]),
        ),
      );
    }
    return {
      format: EXPORT_FORMAT,
      formatVersion: EXPORT_FORMAT_VERSION,
      generatedAtUtc: this.clock.now().toISOString(),
      userId,
      notice: EXPORT_NOTICE,
      omittedColumns: Object.entries(OMITTED_COLUMNS).flatMap(([table, columns]) =>
        (columns ?? []).map((column) => `${table}.${column}`),
      ),
      tables,
    };
  }

  private async run(jobId: string, userId: string): Promise<void> {
    try {
      const result = await this.build(userId);
      const now = this.clock.now();
      await this.prisma.$transaction(async (tx) => {
        const completed = await tx.dataExportJob.updateMany({
          where: { id: jobId, status: 'running' },
          data: {
            status: 'completed',
            result,
            resultBytes: Buffer.byteLength(JSON.stringify(result)),
            completedAtUtc: now,
            expiresAtUtc: addDays(now, EXPORT_RETENTION_DAYS),
          },
        });
        if (completed.count === 1) {
          await this.audit.record({ userId, action: 'data_exported', entity: { type: 'data_export_job', id: jobId } }, tx);
        }
      });
    } catch (error) {
      // Only the error class is logged: messages from the database can contain row values.
      this.logger.error({ jobId, errorName: error instanceof Error ? error.name : 'unknown' }, 'Account export failed');
      await this.prisma.dataExportJob.updateMany({
        where: { id: jobId, status: 'running' },
        data: { status: 'failed', failureCode: 'export_failed', completedAtUtc: this.clock.now() },
      });
    }
  }
}
