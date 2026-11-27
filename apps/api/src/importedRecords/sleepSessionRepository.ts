import { Injectable } from '@nestjs/common';
import { assertNoForbiddenFields, isMissingReason, ValidationError, type MissingReason, type ZonedTimestamp } from '@flowwave/core';
import { PrismaService } from '../prisma/prismaService.js';
import { importIdempotently, type ImportResult } from './idempotentImport.js';
import { requireActiveDataSource, requireUuid } from './ownership.js';
import { requireDate, requireNonBlank, zonedColumns } from './zonedColumns.js';

/** Stage durations in minutes. Stages the source did not report are omitted, never zero. */
export type SleepStages =
  | {
      readonly status: 'present';
      readonly deepSleepMinutes?: number;
      readonly lightSleepMinutes?: number;
      readonly remSleepMinutes?: number;
      readonly awakeMinutes?: number;
    }
  | { readonly status: 'missing'; readonly reason: MissingReason };

export interface SleepSessionImport {
  readonly dataSourceId: string;
  readonly start: ZonedTimestamp;
  readonly end: ZonedTimestamp;
  readonly stages: SleepStages;
  readonly sourceRecordId?: string;
  readonly sourceUpdatedAt: Date;
  readonly idempotencyKey: string;
}

@Injectable()
export class SleepSessionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async importSession(userId: string, session: SleepSessionImport): Promise<ImportResult> {
    assertNoForbiddenFields(session);
    requireUuid('userId', userId);
    await requireActiveDataSource(this.prisma, userId, session.dataSourceId);

    const start = zonedColumns('start', session.start);
    const end = zonedColumns('end', session.end);
    const idempotencyKey = requireNonBlank('idempotencyKey', session.idempotencyKey);
    const sourceRecordId =
      session.sourceRecordId === undefined ? null : requireNonBlank('sourceRecordId', session.sourceRecordId);
    const sourceUpdatedAtUtc = requireDate('sourceUpdatedAt', session.sourceUpdatedAt);

    const content = {
      dataSourceId: session.dataSourceId,
      startAtUtc: start.atUtc,
      startTimeZone: start.timeZone,
      startUtcOffsetMinutes: start.utcOffsetMinutes,
      endAtUtc: end.atUtc,
      endTimeZone: end.timeZone,
      endUtcOffsetMinutes: end.utcOffsetMinutes,
      ...stageColumns(session.stages),
      sourceRecordId,
    };

    return importIdempotently({
      idempotencyKey,
      sourceUpdatedAt: sourceUpdatedAtUtc,
      content,
      insert: async (id) =>
        (
          await this.prisma.sleepSession.createMany({
            data: [{ id, userId, ...content, sourceUpdatedAtUtc, idempotencyKey }],
            skipDuplicates: true,
          })
        ).count,
      findExisting: () =>
        this.prisma.sleepSession.findFirst({
          where: {
            userId,
            OR: [
              { idempotencyKey },
              ...(sourceRecordId === null ? [] : [{ dataSourceId: session.dataSourceId, sourceRecordId }]),
            ],
          },
        }),
      updateIfOlder: async (id) =>
        (
          await this.prisma.sleepSession.updateMany({
            where: { id, userId, sourceUpdatedAtUtc: { lt: sourceUpdatedAtUtc } },
            data: { ...content, sourceUpdatedAtUtc, deletedAtUtc: null, version: { increment: 1 } },
          })
        ).count,
    });
  }
}

function stageColumns(stages: SleepStages): {
  deepSleepMinutes: number | null;
  lightSleepMinutes: number | null;
  remSleepMinutes: number | null;
  awakeMinutes: number | null;
  stagesMissingReason: MissingReason | null;
} {
  if (stages.status === 'missing') {
    if (!isMissingReason(stages.reason)) {
      throw new ValidationError('stages.reason', 'Unknown missing reason.');
    }
    return {
      deepSleepMinutes: null,
      lightSleepMinutes: null,
      remSleepMinutes: null,
      awakeMinutes: null,
      stagesMissingReason: stages.reason,
    };
  }
  const columns = {
    deepSleepMinutes: stages.deepSleepMinutes ?? null,
    lightSleepMinutes: stages.lightSleepMinutes ?? null,
    remSleepMinutes: stages.remSleepMinutes ?? null,
    awakeMinutes: stages.awakeMinutes ?? null,
    stagesMissingReason: null,
  };
  if (
    columns.deepSleepMinutes === null &&
    columns.lightSleepMinutes === null &&
    columns.remSleepMinutes === null &&
    columns.awakeMinutes === null
  ) {
    throw new ValidationError('stages', 'Present stages need at least one duration; use status "missing" otherwise.');
  }
  return columns;
}
