import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, describe, it } from 'node:test';
import {
  createZonedTimestamp,
  ForbiddenDataError,
  IdempotencyConflictError,
  ValidationError,
  type ZonedTimestamp,
} from '@flowwave/core';
import { DeviceUsageBucketRepository, type DeviceUsageBucketImport } from '../src/importedRecords/deviceUsageBucketRepository.js';
import { HealthSampleRepository, type HealthSampleImport } from '../src/importedRecords/healthSampleRepository.js';
import { decideExistingImport, sameColumnValues } from '../src/importedRecords/idempotentImport.js';
import { SleepSessionRepository, type SleepSessionImport } from '../src/importedRecords/sleepSessionRepository.js';
import { translateDatabaseError } from '../src/prisma/databaseErrors.js';
import { PrismaService } from '../src/prisma/prismaService.js';
import { TEST_CONFIG } from './support/testApp.js';

const at = (iso: string, zone = 'Europe/Budapest'): ZonedTimestamp => createZonedTimestamp(iso, zone);

describe('decideExistingImport', () => {
  const base = { idempotencyKey: 'k', storedSourceUpdatedAt: new Date('2026-11-26T10:00:00Z') };

  it('treats identical content as a retried import', () => {
    assert.equal(decideExistingImport({ ...base, sameContent: true, incomingSourceUpdatedAt: new Date(0) }), 'unchanged');
  });

  it('updates only when the source version is newer', () => {
    assert.equal(
      decideExistingImport({ ...base, sameContent: false, incomingSourceUpdatedAt: new Date('2026-11-26T11:00:00Z') }),
      'update',
    );
    assert.equal(
      decideExistingImport({ ...base, sameContent: false, incomingSourceUpdatedAt: new Date('2026-11-26T09:00:00Z') }),
      'stale',
    );
  });

  it('rejects different content with the same source version', () => {
    assert.throws(
      () => decideExistingImport({ ...base, sameContent: false, incomingSourceUpdatedAt: base.storedSourceUpdatedAt }),
      IdempotencyConflictError,
    );
  });
});

describe('sameColumnValues', () => {
  it('compares dates by instant and other values strictly', () => {
    const stored = { a: new Date('2026-11-26T10:00:00Z'), b: 1, c: null, extra: 'ignored' };
    assert.equal(sameColumnValues(stored, { a: new Date('2026-11-26T10:00:00.000Z'), b: 1, c: null }), true);
    assert.equal(sameColumnValues(stored, { b: 2 }), false);
    assert.equal(sameColumnValues(stored, { c: 0 }), false, 'missing is not zero');
    assert.equal(sameColumnValues(stored, { a: '2026-11-26T10:00:00Z' }), false);
  });
});

describe('translateDatabaseError', () => {
  const driverError = (code: string, message: string) => ({
    meta: { driverAdapterError: { cause: { originalCode: code, originalMessage: message, detail: 'Failing row contains (72, 64)' } } },
  });

  it('names the violated constraint without the failing row', () => {
    const translated = translateDatabaseError(
      driverError('23514', 'new row for relation "health_samples" violates check constraint "health_samples_value_range"'),
    );
    assert.ok(translated instanceof ValidationError);
    assert.match(translated.message, /health_samples_value_range/);
    assert.doesNotMatch(translated.message, /Failing row|72/);
    assert.equal(translated.cause, undefined);
  });

  it('translates foreign-key violations and leaves other errors alone', () => {
    assert.ok(translateDatabaseError(driverError('23503', 'violates foreign key constraint "x_fkey"')) instanceof ValidationError);
    const other = new Error('connection refused');
    assert.equal(translateDatabaseError(other), other);
    const duplicate = driverError('23505', 'duplicate key');
    assert.equal(translateDatabaseError(duplicate), duplicate);
  });
});

const databaseUrl = process.env['FLOWWAVE_TEST_DATABASE_URL'];

describe('idempotent imports against PostgreSQL', { skip: !databaseUrl }, () => {
  let prisma: PrismaService;
  let samples: HealthSampleRepository;
  let sleep: SleepSessionRepository;
  let usage: DeviceUsageBucketRepository;
  const userA = randomUUID();
  const userB = randomUUID();
  const sourceA = randomUUID();
  const sourceB = randomUUID();
  const deviceA = randomUUID();

  before(async () => {
    prisma = new PrismaService({ ...TEST_CONFIG, databaseUrl: databaseUrl! });
    samples = new HealthSampleRepository(prisma);
    sleep = new SleepSessionRepository(prisma);
    usage = new DeviceUsageBucketRepository(prisma);
    await prisma.user.createMany({
      data: [
        { id: userA, homeTimeZone: 'Europe/Budapest', isSynthetic: true },
        { id: userB, homeTimeZone: 'Europe/Warsaw', isSynthetic: true },
      ],
    });
    await prisma.healthDataSource.createMany({
      data: [
        { id: sourceA, userId: userA, kind: 'synthetic', sourceKey: 'synthetic:test-a' },
        { id: sourceB, userId: userB, kind: 'synthetic', sourceKey: 'synthetic:test-b' },
      ],
    });
    await prisma.device.create({ data: { id: deviceA, userId: userA, platform: 'android' } });
  });

  after(async () => {
    await prisma.user.deleteMany({ where: { id: { in: [userA, userB] } } });
    await prisma.$disconnect();
  });

  const steps = (overrides: Partial<HealthSampleImport> = {}): HealthSampleImport => ({
    dataSourceId: sourceA,
    metric: 'steps',
    start: at('2026-11-26T07:00:00Z'),
    end: at('2026-11-26T08:00:00Z'),
    value: { status: 'present', value: 1234 },
    sourceUpdatedAt: new Date('2026-11-26T08:05:00Z'),
    idempotencyKey: `steps:${randomUUID()}`,
    ...overrides,
  });

  it('stores a repeated import once and leaves the row untouched', async () => {
    const sample = steps();
    const first = await samples.importSample(userA, sample);
    const before = await prisma.healthSample.findUniqueOrThrow({ where: { id: first.id } });
    const second = await samples.importSample(userA, sample);
    const afterRetry = await prisma.healthSample.findUniqueOrThrow({ where: { id: first.id } });

    assert.equal(first.outcome, 'inserted');
    assert.deepEqual(second, { outcome: 'unchanged', id: first.id });
    assert.equal(await prisma.healthSample.count({ where: { userId: userA, idempotencyKey: sample.idempotencyKey } }), 1);
    assert.equal(afterRetry.updatedAtUtc.getTime(), before.updatedAtUtc.getTime());
    assert.equal(afterRetry.unit, 'count');
    assert.equal(afterRetry.startTimeZone, 'Europe/Budapest');
    assert.equal(afterRetry.startUtcOffsetMinutes, 60);
  });

  it('inserts exactly once under concurrent imports of the same record', async () => {
    const sample = steps();
    const results = await Promise.all(Array.from({ length: 8 }, () => samples.importSample(userA, sample)));

    assert.equal(results.filter((r) => r.outcome === 'inserted').length, 1);
    assert.equal(results.filter((r) => r.outcome === 'unchanged').length, 7);
    assert.equal(new Set(results.map((r) => r.id)).size, 1);
    assert.equal(await prisma.healthSample.count({ where: { userId: userA, idempotencyKey: sample.idempotencyKey } }), 1);
  });

  it('applies newer source versions and ignores older ones', async () => {
    const original = steps();
    const { id } = await samples.importSample(userA, original);

    const newer = { ...original, value: { status: 'present' as const, value: 1500 }, sourceUpdatedAt: new Date('2026-11-26T09:00:00Z') };
    assert.deepEqual(await samples.importSample(userA, newer), { outcome: 'updated', id });

    const older = { ...original, value: { status: 'present' as const, value: 900 }, sourceUpdatedAt: new Date('2026-11-26T08:30:00Z') };
    assert.deepEqual(await samples.importSample(userA, older), { outcome: 'stale', id });

    const stored = await prisma.healthSample.findUniqueOrThrow({ where: { id } });
    assert.equal(stored.value, 1500);
    assert.equal(stored.sourceUpdatedAtUtc.toISOString(), '2026-11-26T09:00:00.000Z');

    await assert.rejects(
      samples.importSample(userA, { ...newer, value: { status: 'present', value: 1 } }),
      IdempotencyConflictError,
    );
  });

  it('deduplicates Health Connect records by source record ID across import keys', async () => {
    const record = steps({
      metric: 'resting_heart_rate',
      start: at('2026-11-26T00:00:00Z'),
      end: at('2026-11-26T23:59:00Z'),
      value: { status: 'present', value: 58 },
      sourceRecordId: `hc-${randomUUID()}`,
    });
    const first = await samples.importSample(userA, record);
    const reimport = await samples.importSample(userA, { ...record, idempotencyKey: `other:${randomUUID()}` });

    assert.deepEqual(reimport, { outcome: 'unchanged', id: first.id });
    assert.equal(await prisma.healthSample.count({ where: { userId: userA, sourceRecordId: record.sourceRecordId! } }), 1);
  });

  it('stores missing values as NULL with a reason, never as zero', async () => {
    const { id } = await samples.importSample(userA, steps({ value: { status: 'missing', reason: 'not_recorded' } }));
    const stored = await prisma.healthSample.findUniqueOrThrow({ where: { id } });

    assert.equal(stored.value, null);
    assert.equal(stored.valueMissingReason, 'not_recorded');
  });

  it('keeps users isolated', async () => {
    const shared = steps();
    const a = await samples.importSample(userA, shared);
    const b = await samples.importSample(userB, { ...shared, dataSourceId: sourceB });

    assert.equal(b.outcome, 'inserted');
    assert.notEqual(a.id, b.id);
    await assert.rejects(samples.importSample(userB, steps()), ValidationError);
    assert.equal(await prisma.healthSample.count({ where: { userId: userB, dataSourceId: sourceA } }), 0);
  });

  it('rejects forbidden fields and invalid offsets before writing', async () => {
    const withWindowTitle = { ...steps(), windowTitle: 'Quarterly report.docx' } as HealthSampleImport;
    await assert.rejects(samples.importSample(userA, withWindowTitle), ForbiddenDataError);

    const wrongOffset = steps({ start: { utc: '2026-11-26T07:00:00.000Z', timeZone: 'Europe/Budapest', utcOffsetMinutes: 0 } });
    await assert.rejects(samples.importSample(userA, wrongOffset), ValidationError);
    assert.equal(await prisma.healthSample.count({ where: { idempotencyKey: wrongOffset.idempotencyKey } }), 0);
  });

  it('reports database rule violations as validation errors without values', async () => {
    const heartRateWithoutRange = steps({
      metric: 'heart_rate',
      start: at('2026-11-26T07:00:00Z'),
      end: at('2026-11-26T07:05:00Z'),
      value: { status: 'present', value: 71 },
    });
    await assert.rejects(samples.importSample(userA, heartRateWithoutRange), (error: unknown) => {
      assert.ok(error instanceof ValidationError);
      assert.match(error.message, /health_samples_heart_rate_range_columns/);
      assert.doesNotMatch(error.message, /71/);
      return true;
    });
  });

  it('imports sleep sessions idempotently and versions updates', async () => {
    const session: SleepSessionImport = {
      dataSourceId: sourceA,
      start: at('2026-11-25T22:30:00Z'),
      end: at('2026-11-26T06:00:00Z'),
      stages: { status: 'present', deepSleepMinutes: 80, lightSleepMinutes: 250, remSleepMinutes: 90 },
      sourceRecordId: `hc-sleep-${randomUUID()}`,
      sourceUpdatedAt: new Date('2026-11-26T06:10:00Z'),
      idempotencyKey: `sleep:${randomUUID()}`,
    };
    const first = await sleep.importSession(userA, session);
    assert.equal((await sleep.importSession(userA, session)).outcome, 'unchanged');

    const corrected = { ...session, end: at('2026-11-26T06:30:00Z'), sourceUpdatedAt: new Date('2026-11-26T07:00:00Z') };
    assert.equal((await sleep.importSession(userA, corrected)).outcome, 'updated');

    const stored = await prisma.sleepSession.findUniqueOrThrow({ where: { id: first.id } });
    assert.equal(stored.version, 2);
    assert.equal(stored.awakeMinutes, null, 'unreported stage stays missing');
    assert.equal(stored.endAtUtc.toISOString(), '2026-11-26T06:30:00.000Z');
  });

  it('imports usage buckets once per device and bucket, whatever the key', async () => {
    const bucket: DeviceUsageBucketImport = {
      deviceId: deviceA,
      bucketStart: at('2026-11-26T09:00:00Z'),
      metrics: {
        status: 'present',
        screenOnSeconds: 900,
        unlockCount: 3,
        appSwitchCount: 10,
        categorySeconds: {
          productivity: 600,
          communication: 120,
          social: 60,
          entertainment: 0,
          games: 0,
          information: 60,
          other: 30,
        },
      },
      sourceUpdatedAt: new Date('2026-11-26T09:31:00Z'),
      idempotencyKey: `usage:${randomUUID()}`,
    };
    const first = await usage.importBucket(userA, bucket);
    const sameBucketOtherKey = await usage.importBucket(userA, { ...bucket, idempotencyKey: `usage:${randomUUID()}` });

    assert.equal(first.outcome, 'inserted');
    assert.deepEqual(sameBucketOtherKey, { outcome: 'unchanged', id: first.id });

    const noAccess = await usage.importBucket(userA, {
      ...bucket,
      bucketStart: at('2026-11-26T09:30:00Z'),
      metrics: { status: 'missing', reason: 'no_consent' },
      idempotencyKey: `usage:${randomUUID()}`,
    });
    const missing = await prisma.deviceUsageBucket.findUniqueOrThrow({ where: { id: noAccess.id } });
    assert.equal(missing.screenOnSeconds, null);
    assert.equal(missing.missingReason, 'no_consent');
  });
});
