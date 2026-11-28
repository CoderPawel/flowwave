import { Injectable } from '@nestjs/common';
import { assertNoForbiddenFields, isMissingReason, ValidationError, type MissingReason, type ZonedTimestamp } from '@flowwave/core';
import { PrismaService } from '../prisma/prismaService.js';
import { importIdempotently, type ImportResult } from './idempotentImport.js';
import { requireActiveDevice, requireUuid } from './ownership.js';
import { requireDate, requireNonBlank, zonedColumns } from './zonedColumns.js';

/** Categories FlowWave stores. Package names are mapped to these on the phone and discarded. */
export const USAGE_CATEGORIES = [
  'productivity',
  'communication',
  'social',
  'entertainment',
  'games',
  'information',
  'other',
] as const;
export type UsageCategory = (typeof USAGE_CATEGORIES)[number];

export type DeviceUsageMetrics =
  | {
      readonly status: 'present';
      readonly screenOnSeconds: number;
      readonly unlockCount: number;
      readonly appSwitchCount: number;
      readonly categorySeconds: Readonly<Record<UsageCategory, number>>;
    }
  | { readonly status: 'missing'; readonly reason: MissingReason };

export interface DeviceUsageBucketImport {
  readonly deviceId: string;
  /** Start of the 30-minute bucket, aligned to :00 or :30 UTC. */
  readonly bucketStart: ZonedTimestamp;
  readonly metrics: DeviceUsageMetrics;
  readonly sourceUpdatedAt: Date;
  readonly idempotencyKey: string;
}

@Injectable()
export class DeviceUsageBucketRepository {
  constructor(private readonly prisma: PrismaService) {}

  async importBucket(userId: string, bucket: DeviceUsageBucketImport): Promise<ImportResult> {
    assertNoForbiddenFields(bucket);
    requireUuid('userId', userId);
    await requireActiveDevice(this.prisma, userId, bucket.deviceId);

    const bucketStart = zonedColumns('bucketStart', bucket.bucketStart);
    const idempotencyKey = requireNonBlank('idempotencyKey', bucket.idempotencyKey);
    const sourceUpdatedAtUtc = requireDate('sourceUpdatedAt', bucket.sourceUpdatedAt);

    const content = {
      deviceId: bucket.deviceId,
      bucketStartAtUtc: bucketStart.atUtc,
      bucketStartTimeZone: bucketStart.timeZone,
      bucketStartUtcOffsetMinutes: bucketStart.utcOffsetMinutes,
      ...metricColumns(bucket.metrics),
    };

    return importIdempotently({
      idempotencyKey,
      sourceUpdatedAt: sourceUpdatedAtUtc,
      content,
      insert: async (id) =>
        (
          await this.prisma.deviceUsageBucket.createMany({
            data: [{ id, userId, ...content, sourceUpdatedAtUtc, idempotencyKey }],
            skipDuplicates: true,
          })
        ).count,
      findExisting: () =>
        this.prisma.deviceUsageBucket.findFirst({
          where: {
            userId,
            OR: [{ idempotencyKey }, { deviceId: bucket.deviceId, bucketStartAtUtc: bucketStart.atUtc }],
          },
        }),
      updateIfOlder: async (id) =>
        (
          await this.prisma.deviceUsageBucket.updateMany({
            where: { id, userId, sourceUpdatedAtUtc: { lt: sourceUpdatedAtUtc } },
            data: { ...content, sourceUpdatedAtUtc },
          })
        ).count,
    });
  }
}

function metricColumns(metrics: DeviceUsageMetrics) {
  if (metrics.status === 'missing') {
    if (!isMissingReason(metrics.reason)) {
      throw new ValidationError('metrics.reason', 'Unknown missing reason.');
    }
    return {
      missingReason: metrics.reason,
      screenOnSeconds: null,
      unlockCount: null,
      appSwitchCount: null,
      productivitySeconds: null,
      communicationSeconds: null,
      socialSeconds: null,
      entertainmentSeconds: null,
      gamesSeconds: null,
      informationSeconds: null,
      otherSeconds: null,
    };
  }
  const unknown = Object.keys(metrics.categorySeconds).filter(
    (category) => !(USAGE_CATEGORIES as readonly string[]).includes(category),
  );
  if (unknown.length > 0) {
    // Key names are not echoed: an unmapped key could be an app package name.
    throw new ValidationError('metrics.categorySeconds', `${unknown.length} unknown category key(s).`);
  }
  const seconds = metrics.categorySeconds;
  return {
    missingReason: null,
    screenOnSeconds: metrics.screenOnSeconds,
    unlockCount: metrics.unlockCount,
    appSwitchCount: metrics.appSwitchCount,
    productivitySeconds: seconds.productivity,
    communicationSeconds: seconds.communication,
    socialSeconds: seconds.social,
    entertainmentSeconds: seconds.entertainment,
    gamesSeconds: seconds.games,
    informationSeconds: seconds.information,
    otherSeconds: seconds.other,
  };
}
