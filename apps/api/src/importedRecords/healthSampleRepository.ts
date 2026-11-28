import { Injectable } from '@nestjs/common';
import { assertNoForbiddenFields, isMissingReason, ValidationError, type MissingReason, type ZonedTimestamp } from '@flowwave/core';
import type { HealthMetric, MeasurementUnit } from '../../generated/prisma/enums.js';
import { ConsentService } from '../consent/consentService.js';
import { PrismaService } from '../prisma/prismaService.js';
import { importIdempotently, type ImportResult } from './idempotentImport.js';
import { requireActiveDataSource, requireUuid } from './ownership.js';
import { requireDate, requireNonBlank, zonedColumns } from './zonedColumns.js';

export const UNIT_BY_METRIC: Readonly<Record<HealthMetric, MeasurementUnit>> = {
  steps: 'count',
  heart_rate: 'beats_per_minute',
  resting_heart_rate: 'beats_per_minute',
};

/** Consent scope each metric is imported under (decision 0014). */
export const CONSENT_SCOPE_BY_METRIC: Readonly<Record<HealthMetric, string>> = {
  steps: 'steps',
  heart_rate: 'heart_rate',
  resting_heart_rate: 'resting_heart_rate',
};

export type HealthSampleValue =
  | {
      readonly status: 'present';
      /** Sum for steps, average for heart rate, the value for resting heart rate. */
      readonly value: number;
      /** Heart rate only. */
      readonly minValue?: number;
      readonly maxValue?: number;
      readonly sampleCount?: number;
    }
  | { readonly status: 'missing'; readonly reason: MissingReason };

export interface HealthSampleImport {
  readonly dataSourceId: string;
  readonly metric: HealthMetric;
  readonly start: ZonedTimestamp;
  readonly end: ZonedTimestamp;
  readonly value: HealthSampleValue;
  /** Health Connect record ID; omit for values from the aggregate API. */
  readonly sourceRecordId?: string;
  readonly sourceUpdatedAt: Date;
  readonly idempotencyKey: string;
}

@Injectable()
export class HealthSampleRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly consents: ConsentService,
  ) {}

  /** Imports one aggregated sample. Repeating the same import changes nothing. */
  async importSample(userId: string, sample: HealthSampleImport): Promise<ImportResult> {
    assertNoForbiddenFields(sample);
    requireUuid('userId', userId);
    if (!Object.hasOwn(UNIT_BY_METRIC, sample.metric)) {
      throw new ValidationError('metric', 'Unknown health metric.');
    }
    const sourceKind = await requireActiveDataSource(this.prisma, userId, sample.dataSourceId);
    await this.consents.assertHealthDataConsent(userId, sourceKind, CONSENT_SCOPE_BY_METRIC[sample.metric]);

    const start = zonedColumns('start', sample.start);
    const end = zonedColumns('end', sample.end);
    const idempotencyKey = requireNonBlank('idempotencyKey', sample.idempotencyKey);
    const sourceRecordId =
      sample.sourceRecordId === undefined ? null : requireNonBlank('sourceRecordId', sample.sourceRecordId);
    const sourceUpdatedAtUtc = requireDate('sourceUpdatedAt', sample.sourceUpdatedAt);

    const content = {
      dataSourceId: sample.dataSourceId,
      metric: sample.metric,
      unit: UNIT_BY_METRIC[sample.metric],
      startAtUtc: start.atUtc,
      startTimeZone: start.timeZone,
      startUtcOffsetMinutes: start.utcOffsetMinutes,
      endAtUtc: end.atUtc,
      endTimeZone: end.timeZone,
      endUtcOffsetMinutes: end.utcOffsetMinutes,
      ...valueColumns(sample.value),
      sourceRecordId,
    };

    return importIdempotently({
      idempotencyKey,
      sourceUpdatedAt: sourceUpdatedAtUtc,
      content,
      insert: async (id) =>
        (
          await this.prisma.healthSample.createMany({
            data: [{ id, userId, ...content, sourceUpdatedAtUtc, idempotencyKey }],
            skipDuplicates: true,
          })
        ).count,
      findExisting: () =>
        this.prisma.healthSample.findFirst({
          where: {
            userId,
            OR: [
              { idempotencyKey },
              ...(sourceRecordId === null ? [] : [{ dataSourceId: sample.dataSourceId, sourceRecordId }]),
            ],
          },
        }),
      updateIfOlder: async (id) =>
        (
          await this.prisma.healthSample.updateMany({
            where: { id, userId, sourceUpdatedAtUtc: { lt: sourceUpdatedAtUtc } },
            data: { ...content, sourceUpdatedAtUtc, deletedAtUtc: null },
          })
        ).count,
    });
  }
}

function valueColumns(value: HealthSampleValue): {
  value: number | null;
  minValue: number | null;
  maxValue: number | null;
  sampleCount: number | null;
  valueMissingReason: MissingReason | null;
} {
  if (value.status === 'missing') {
    if (!isMissingReason(value.reason)) {
      throw new ValidationError('value.reason', 'Unknown missing reason.');
    }
    return { value: null, minValue: null, maxValue: null, sampleCount: null, valueMissingReason: value.reason };
  }
  if (!Number.isFinite(value.value)) {
    throw new ValidationError('value.value', 'Must be a finite number.');
  }
  return {
    value: value.value,
    minValue: value.minValue ?? null,
    maxValue: value.maxValue ?? null,
    sampleCount: value.sampleCount ?? null,
    valueMissingReason: null,
  };
}
