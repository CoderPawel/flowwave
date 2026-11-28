import { Inject, Injectable } from '@nestjs/common';
import {
  assertConsent,
  assertTypeConsent,
  ConflictError,
  consentStatus,
  CONSENT_TYPES,
  createConsentDecision,
  CURRENT_CONSENT_POLICY_VERSIONS,
  EXTERNAL_DATA_SOURCES,
  isExternalDataSourceId,
  latestConsentDecisionFor,
  parseZonedTimestamp,
  ValidationError,
  type ConsentDecision,
  type ConsentState,
  type ConsentStatus,
  type ConsentType,
  type ExternalDataSourceId,
  type ZonedTimestamp,
} from '@flowwave/core';
import type { Prisma } from '../../generated/prisma/client.js';
import type { HealthSourceKind } from '../../generated/prisma/enums.js';
import { AuditService } from '../audit/auditService.js';
import { addSeconds, CLOCK, type Clock } from '../common/clock.js';
import { requireUuid } from '../importedRecords/ownership.js';
import { isUniqueViolation } from '../prisma/databaseErrors.js';
import { PrismaService } from '../prisma/prismaService.js';

type Reader = Pick<Prisma.TransactionClient, 'consent'>;
type Tx = Prisma.TransactionClient;

export interface ConsentDecisionInput {
  readonly id: string;
  readonly type: string;
  readonly sourceId?: string | null;
  readonly state: ConsentState;
  readonly scopes: readonly string[];
  readonly policyVersion: string;
  readonly decidedAt: ZonedTimestamp;
  /** Only with a withdrawal of `health_data` or `device_usage` (decision 0014). */
  readonly deleteCollectedData?: boolean;
}

export interface RecordedConsent {
  readonly decision: ConsentDecision;
  /** True when the same decision had already been recorded; nothing changed. */
  readonly replayed: boolean;
  readonly deletedRecords: number;
}

export interface ConsentSubjectStatus {
  readonly type: ConsentType;
  readonly sourceId: ExternalDataSourceId | null;
  readonly status: ConsentStatus;
  readonly scopes: readonly string[];
  readonly policyVersion: string | null;
  readonly currentPolicyVersion: string;
  readonly decidedAt: ZonedTimestamp | null;
}

/** Decisions may be recorded offline, but not dated in the future beyond clock drift. */
const MAX_CLOCK_SKEW_SECONDS = 300;

const CONSENT_SELECT = {
  id: true,
  userId: true,
  consentType: true,
  sourceId: true,
  state: true,
  scopes: true,
  policyVersion: true,
  decidedAtUtc: true,
  decidedTimeZone: true,
  decidedUtcOffsetMinutes: true,
} as const;

interface ConsentRow {
  readonly id: string;
  readonly userId: string;
  readonly consentType: ConsentType;
  readonly sourceId: string | null;
  readonly state: string;
  readonly scopes: readonly string[];
  readonly policyVersion: string;
  readonly decidedAtUtc: Date;
  readonly decidedTimeZone: string;
  readonly decidedUtcOffsetMinutes: number;
}

function toDecision(row: ConsentRow): ConsentDecision {
  return {
    id: row.id,
    type: row.consentType,
    sourceId: isExternalDataSourceId(row.sourceId) ? row.sourceId : null,
    state: row.state === 'granted' ? 'granted' : 'revoked',
    scopes: [...row.scopes].sort(),
    policyVersion: row.policyVersion,
    decidedAt: {
      utc: row.decidedAtUtc.toISOString(),
      timeZone: row.decidedTimeZone,
      utcOffsetMinutes: row.decidedUtcOffsetMinutes,
    },
  };
}

function sameDecision(a: ConsentDecision, b: ConsentDecision): boolean {
  return (
    a.type === b.type &&
    a.sourceId === b.sourceId &&
    a.state === b.state &&
    a.policyVersion === b.policyVersion &&
    a.scopes.join(',') === b.scopes.join(',') &&
    a.decidedAt.utc === b.decidedAt.utc &&
    a.decidedAt.timeZone === b.decidedAt.timeZone &&
    a.decidedAt.utcOffsetMinutes === b.decidedAt.utcOffsetMinutes
  );
}

@Injectable()
export class ConsentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Records one decision. Repeating it is safe; reusing its ID for a different decision is a conflict. */
  async record(userId: string, input: ConsentDecisionInput): Promise<RecordedConsent> {
    const decision = this.validate(input);
    try {
      return await this.prisma.$transaction((tx) => this.insert(tx, userId, decision, input.deleteCollectedData === true));
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      // A concurrent request recorded the same ID first.
      return this.prisma.$transaction((tx) => this.insert(tx, userId, decision, input.deleteCollectedData === true));
    }
  }

  async loadLog(userId: string, reader: Reader = this.prisma): Promise<ConsentDecision[]> {
    const rows = await reader.consent.findMany({ where: { userId }, select: CONSENT_SELECT });
    return rows.map(toDecision);
  }

  async history(userId: string): Promise<ConsentDecision[]> {
    const rows = await this.prisma.consent.findMany({
      where: { userId },
      select: CONSENT_SELECT,
      orderBy: [{ decidedAtUtc: 'desc' }, { createdAtUtc: 'desc' }],
    });
    return rows.map(toDecision);
  }

  /** Current state of every consent the app can ask for, including ones never asked. */
  async status(userId: string): Promise<ConsentSubjectStatus[]> {
    const log = await this.loadLog(userId);
    const subjects: Array<{ type: ConsentType; sourceId: ExternalDataSourceId | null }> = [];
    for (const type of CONSENT_TYPES) {
      if (type === 'health_data') {
        for (const sourceId of Object.keys(EXTERNAL_DATA_SOURCES) as ExternalDataSourceId[]) {
          subjects.push({ type, sourceId });
        }
      } else {
        subjects.push({ type, sourceId: null });
      }
    }
    return subjects.map(({ type, sourceId }) => {
      const latest = latestConsentDecisionFor(log, type, sourceId);
      const status = consentStatus(log, type, sourceId);
      return {
        type,
        sourceId,
        status,
        scopes: status === 'granted' && latest ? latest.scopes : [],
        policyVersion: latest?.policyVersion ?? null,
        currentPolicyVersion: CURRENT_CONSENT_POLICY_VERSIONS[type],
        decidedAt: latest?.decidedAt ?? null,
      };
    });
  }

  /** Health data from an external source needs consent for the scope; manual and synthetic entries do not. */
  async assertHealthDataConsent(userId: string, sourceKind: HealthSourceKind, scope: string): Promise<void> {
    if (!isExternalDataSourceId(sourceKind)) return;
    assertConsent(await this.loadLog(userId), sourceKind, scope);
  }

  async assertDeviceUsageConsent(userId: string): Promise<void> {
    assertTypeConsent(await this.loadLog(userId), 'device_usage');
  }

  private validate(input: ConsentDecisionInput): ConsentDecision {
    requireUuid('id', input.id);
    let decidedAt: ZonedTimestamp;
    try {
      decidedAt = parseZonedTimestamp(input.decidedAt);
    } catch (error) {
      throw new ValidationError('decidedAt', error instanceof Error ? error.message : 'Invalid zoned timestamp.');
    }
    if (new Date(decidedAt.utc) > addSeconds(this.clock.now(), MAX_CLOCK_SKEW_SECONDS)) {
      throw new ValidationError('decidedAt', 'Must not be in the future.');
    }
    const decision = createConsentDecision({
      id: input.id,
      type: input.type,
      sourceId: input.sourceId ?? null,
      state: input.state,
      scopes: input.scopes,
      policyVersion: input.policyVersion,
      decidedAt,
    });
    const current = CURRENT_CONSENT_POLICY_VERSIONS[decision.type];
    if (decision.state === 'granted' && decision.policyVersion !== current) {
      throw new ValidationError('policyVersion', `A grant must use the current consent text version (${current}).`);
    }
    if (input.deleteCollectedData === true) {
      if (decision.state !== 'revoked' || (decision.type !== 'health_data' && decision.type !== 'device_usage')) {
        throw new ValidationError(
          'deleteCollectedData',
          'Only a withdrawal of health data or device usage consent can delete collected data.',
        );
      }
    }
    return decision;
  }

  private async insert(tx: Tx, userId: string, decision: ConsentDecision, deleteData: boolean): Promise<RecordedConsent> {
    const existing = await tx.consent.findUnique({ where: { id: decision.id }, select: CONSENT_SELECT });
    if (existing) {
      if (existing.userId === userId && sameDecision(toDecision(existing), decision)) {
        return { decision: toDecision(existing), replayed: true, deletedRecords: 0 };
      }
      throw new ConflictError('id', 'This decision ID was already used for a different decision.');
    }
    await tx.consent.create({
      data: {
        id: decision.id,
        userId,
        consentType: decision.type,
        sourceId: decision.sourceId,
        state: decision.state,
        scopes: [...decision.scopes],
        policyVersion: decision.policyVersion,
        decidedAtUtc: new Date(decision.decidedAt.utc),
        decidedTimeZone: decision.decidedAt.timeZone,
        decidedUtcOffsetMinutes: decision.decidedAt.utcOffsetMinutes,
      },
    });
    await this.audit.record(
      {
        userId,
        action: 'consent_recorded',
        entity: { type: 'consent_decision', id: decision.id },
        metadata: {
          consentType: decision.type,
          sourceId: decision.sourceId,
          state: decision.state,
          policyVersion: decision.policyVersion,
        },
      },
      tx,
    );
    const deletedRecords = deleteData ? await this.deleteCollectedData(tx, userId, decision) : 0;
    return { decision, replayed: false, deletedRecords };
  }

  private async deleteCollectedData(tx: Tx, userId: string, decision: ConsentDecision): Promise<number> {
    let deleted = 0;
    if (decision.type === 'device_usage') {
      deleted = (await tx.deviceUsageBucket.deleteMany({ where: { userId } })).count;
    } else if (decision.sourceId) {
      const sources = await tx.healthDataSource.findMany({
        where: { userId, kind: decision.sourceId },
        select: { id: true },
      });
      const dataSourceId = { in: sources.map((source) => source.id) };
      deleted += (await tx.healthSample.deleteMany({ where: { userId, dataSourceId } })).count;
      deleted += (await tx.sleepSession.deleteMany({ where: { userId, dataSourceId } })).count;
      deleted += (await tx.activitySession.deleteMany({ where: { userId, dataSourceId } })).count;
      await tx.healthDataSource.updateMany({
        where: { userId, kind: decision.sourceId, deletedAtUtc: null },
        data: { deletedAtUtc: this.clock.now() },
      });
    }
    await this.audit.record(
      {
        userId,
        action: 'data_deleted',
        entity: { type: 'consent_decision', id: decision.id },
        metadata: { consentType: decision.type, sourceId: decision.sourceId, records: deleted },
      },
      tx,
    );
    return deleted;
  }
}
