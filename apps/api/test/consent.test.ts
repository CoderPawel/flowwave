import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, describe, it } from 'node:test';
import type { INestApplication } from '@nestjs/common';
import {
  ConsentRequiredError,
  createZonedTimestamp,
  CURRENT_CONSENT_POLICY_VERSIONS,
  type ConsentType,
} from '@flowwave/core';
import { DeviceUsageBucketRepository, type DeviceUsageBucketImport } from '../src/importedRecords/deviceUsageBucketRepository.js';
import { HealthSampleRepository, type HealthSampleImport } from '../src/importedRecords/healthSampleRepository.js';
import { SleepSessionRepository } from '../src/importedRecords/sleepSessionRepository.js';
import { PrismaService } from '../src/prisma/prismaService.js';
import { apiClient } from './support/apiClient.js';
import { startTestApp, TEST_CONFIG } from './support/testApp.js';

const databaseUrl = process.env['FLOWWAVE_TEST_DATABASE_URL'];
const HC = 'health_connect';

interface StatusRow {
  type: ConsentType;
  sourceId: string | null;
  status: string;
  scopes: string[];
}

describe('consent API against PostgreSQL', { skip: !databaseUrl }, () => {
  const config = { ...TEST_CONFIG, databaseUrl: databaseUrl! };
  let app: INestApplication;
  let api: ReturnType<typeof apiClient>;
  let prisma: PrismaService;
  let samples: HealthSampleRepository;
  let sleep: SleepSessionRepository;
  let usage: DeviceUsageBucketRepository;
  const userIds: string[] = [];
  let minute = 0;

  /** Each decision is a little later than the previous one, as on a real phone. */
  function decidedAt() {
    minute += 1;
    return createZonedTimestamp(new Date(Date.UTC(2026, 10, 27, 8, minute)), 'Europe/Budapest');
  }

  function decision(type: ConsentType, state: 'granted' | 'revoked', extra: Record<string, unknown> = {}) {
    return {
      id: randomUUID(),
      type,
      state,
      scopes: [],
      policyVersion: CURRENT_CONSENT_POLICY_VERSIONS[type],
      decidedAt: decidedAt(),
      ...extra,
    };
  }

  async function user() {
    const { tokens } = await api.register();
    userIds.push(tokens.userId);
    return tokens;
  }

  async function statusOf(token: string, type: ConsentType, sourceId: string | null = null) {
    const response = await api.call<StatusRow[]>('GET', '/v1/consents', { token });
    return response.body.find((row) => row.type === type && row.sourceId === sourceId);
  }

  const stepsSample = (dataSourceId: string, overrides: Partial<HealthSampleImport> = {}): HealthSampleImport => ({
    dataSourceId,
    metric: 'steps',
    start: createZonedTimestamp('2026-11-26T07:00:00Z', 'Europe/Budapest'),
    end: createZonedTimestamp('2026-11-26T08:00:00Z', 'Europe/Budapest'),
    value: { status: 'present', value: 900 },
    sourceUpdatedAt: new Date('2026-11-26T08:05:00Z'),
    idempotencyKey: `steps:${randomUUID()}`,
    ...overrides,
  });

  let bucketIndex = 0;
  const usageBucket = (deviceId: string): DeviceUsageBucketImport => ({
    deviceId,
    bucketStart: createZonedTimestamp(new Date(Date.UTC(2026, 10, 20) + (bucketIndex += 1) * 1_800_000), 'UTC'),
    metrics: {
      status: 'present',
      screenOnSeconds: 600,
      unlockCount: 3,
      appSwitchCount: 10,
      categorySeconds: { productivity: 300, communication: 100, social: 0, entertainment: 0, games: 0, information: 100, other: 100 },
    },
    sourceUpdatedAt: new Date('2026-11-26T09:00:00Z'),
    idempotencyKey: `usage:${randomUUID()}`,
  });

  before(async () => {
    const started = await startTestApp(config);
    app = started.app;
    api = apiClient(started.baseUrl);
    prisma = new PrismaService(config);
    samples = app.get(HealthSampleRepository);
    sleep = app.get(SleepSessionRepository);
    usage = app.get(DeviceUsageBucketRepository);
  });

  after(async () => {
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('starts with every consent not asked, health data per source', async () => {
    const tokens = await user();
    const response = await api.call<StatusRow[]>('GET', '/v1/consents', { token: tokens.accessToken });
    assert.equal(response.status, 200);
    assert.deepEqual(
      response.body.map((row) => `${row.type}:${row.sourceId ?? '-'}:${row.status}`).sort(),
      [
        'analytics:-:not_asked',
        'device_usage:-:not_asked',
        'health_data:apple_health:not_asked',
        'health_data:health_connect:not_asked',
        'notifications:-:not_asked',
      ],
    );
  });

  it('grants and withdraws each consent type independently', async () => {
    const tokens = await user();
    const token = tokens.accessToken;
    for (const type of ['device_usage', 'notifications', 'analytics'] as const) {
      assert.equal((await api.call('POST', '/v1/consents', { token, body: decision(type, 'granted') })).status, 201);
    }
    assert.equal(
      (await api.call('POST', '/v1/consents', { token, body: decision('health_data', 'granted', { sourceId: HC, scopes: ['steps'] }) })).status,
      201,
    );
    assert.equal((await api.call('POST', '/v1/consents', { token, body: decision('analytics', 'revoked') })).status, 201);

    assert.equal((await statusOf(token, 'analytics'))?.status, 'revoked');
    assert.equal((await statusOf(token, 'notifications'))?.status, 'granted');
    assert.equal((await statusOf(token, 'device_usage'))?.status, 'granted');
    assert.deepEqual((await statusOf(token, 'health_data', HC))?.scopes, ['steps']);
    assert.equal((await statusOf(token, 'health_data', 'apple_health'))?.status, 'not_asked');
  });

  it('accepts grants only under the current consent text; withdrawals under any', async () => {
    const tokens = await user();
    const token = tokens.accessToken;
    const oldGrant = await api.call('POST', '/v1/consents', {
      token,
      body: decision('notifications', 'granted', { policyVersion: '2020-01-01' }),
    });
    assert.equal(oldGrant.status, 400);
    assert.equal(oldGrant.body['field'], 'policyVersion');
    const oldRevoke = await api.call('POST', '/v1/consents', {
      token,
      body: decision('notifications', 'revoked', { policyVersion: '2020-01-01' }),
    });
    assert.equal(oldRevoke.status, 201);
  });

  it('reports a grant under an older text as outdated and refuses data until asked again', async () => {
    const tokens = await user();
    await prisma.consent.create({
      data: {
        id: randomUUID(),
        userId: tokens.userId,
        consentType: 'device_usage',
        state: 'granted',
        scopes: [],
        policyVersion: '2020-01-01',
        decidedAtUtc: new Date('2026-01-01T00:00:00Z'),
        decidedTimeZone: 'UTC',
        decidedUtcOffsetMinutes: 0,
      },
    });
    assert.equal((await statusOf(tokens.accessToken, 'device_usage'))?.status, 'outdated');
    await assert.rejects(usage.importBucket(tokens.userId, usageBucket(tokens.deviceId)), ConsentRequiredError);
  });

  it('records a repeated decision once and rejects a reused ID with different content', async () => {
    const tokens = await user();
    const body = decision('notifications', 'granted');
    assert.equal((await api.call('POST', '/v1/consents', { token: tokens.accessToken, body })).status, 201);
    const replay = await api.call('POST', '/v1/consents', { token: tokens.accessToken, body });
    assert.equal(replay.status, 200);
    assert.equal(replay.body['replayed'], true);
    const changed = await api.call('POST', '/v1/consents', { token: tokens.accessToken, body: { ...body, state: 'revoked' } });
    assert.equal(changed.status, 409);
    const other = await user();
    assert.equal((await api.call('POST', '/v1/consents', { token: other.accessToken, body })).status, 409, 'IDs are global');
    assert.equal(await prisma.consent.count({ where: { id: body.id } }), 1);
    assert.equal(await prisma.auditEvent.count({ where: { userId: tokens.userId, action: 'consent_recorded' } }), 1);
  });

  it('rejects unknown types, scopes, and data deletion with a grant', async () => {
    const tokens = await user();
    const token = tokens.accessToken;
    const statuses = await Promise.all([
      api.call('POST', '/v1/consents', { token, body: decision('notifications', 'granted', { type: 'location' }) }),
      api.call('POST', '/v1/consents', { token, body: decision('health_data', 'granted', { sourceId: HC, scopes: ['blood_glucose'] }) }),
      api.call('POST', '/v1/consents', { token, body: decision('notifications', 'granted', { scopes: ['steps'] }) }),
      api.call('POST', '/v1/consents', { token, body: decision('health_data', 'granted', { scopes: ['steps'] }) }),
      api.call('POST', '/v1/consents', { token, body: decision('device_usage', 'granted', { deleteCollectedData: true }) }),
      api.call('POST', '/v1/consents', { token, body: decision('notifications', 'revoked', { deleteCollectedData: true }) }),
    ]);
    assert.deepEqual(statuses.map((response) => response.status), [400, 400, 400, 400, 400, 400]);
    assert.equal(await prisma.consent.count({ where: { userId: tokens.userId } }), 0);
  });

  it('stops imports as soon as consent is withdrawn', async () => {
    const tokens = await user();
    const token = tokens.accessToken;
    const source = await prisma.healthDataSource.create({
      data: { userId: tokens.userId, kind: HC, sourceKey: `health-connect:${randomUUID()}` },
    });

    await assert.rejects(samples.importSample(tokens.userId, stepsSample(source.id)), ConsentRequiredError, 'never asked');
    await assert.rejects(usage.importBucket(tokens.userId, usageBucket(tokens.deviceId)), ConsentRequiredError);

    await api.call('POST', '/v1/consents', { token, body: decision('health_data', 'granted', { sourceId: HC, scopes: ['steps'] }) });
    await api.call('POST', '/v1/consents', { token, body: decision('device_usage', 'granted') });
    assert.equal((await samples.importSample(tokens.userId, stepsSample(source.id))).outcome, 'inserted');
    assert.equal((await usage.importBucket(tokens.userId, usageBucket(tokens.deviceId))).outcome, 'inserted');
    await assert.rejects(
      samples.importSample(tokens.userId, stepsSample(source.id, { metric: 'heart_rate', value: { status: 'present', value: 70 } })),
      (error: unknown) => error instanceof ConsentRequiredError && error.scope === 'heart_rate',
      'a scope that was not granted',
    );
    await assert.rejects(
      sleep.importSession(tokens.userId, {
        dataSourceId: source.id,
        start: createZonedTimestamp('2026-11-25T22:00:00Z', 'Europe/Budapest'),
        end: createZonedTimestamp('2026-11-26T06:00:00Z', 'Europe/Budapest'),
        stages: { status: 'missing', reason: 'not_recorded' },
        sourceUpdatedAt: new Date('2026-11-26T06:10:00Z'),
        idempotencyKey: `sleep:${randomUUID()}`,
      }),
      (error: unknown) => error instanceof ConsentRequiredError && error.scope === 'sleep_duration',
    );

    await api.call('POST', '/v1/consents', { token, body: decision('health_data', 'revoked', { sourceId: HC }) });
    await api.call('POST', '/v1/consents', { token, body: decision('device_usage', 'revoked') });
    await assert.rejects(samples.importSample(tokens.userId, stepsSample(source.id)), ConsentRequiredError);
    await assert.rejects(usage.importBucket(tokens.userId, usageBucket(tokens.deviceId)), ConsentRequiredError);
    assert.equal(await prisma.healthSample.count({ where: { userId: tokens.userId } }), 1, 'withdrawal alone keeps collected data');
  });

  it('deletes only the withdrawn type\'s data when asked, and keeps the full history', async () => {
    const tokens = await user();
    const token = tokens.accessToken;
    const hc = await prisma.healthDataSource.create({ data: { userId: tokens.userId, kind: HC, sourceKey: `health-connect:${randomUUID()}` } });
    const synthetic = await prisma.healthDataSource.create({
      data: { userId: tokens.userId, kind: 'synthetic', sourceKey: `synthetic:${randomUUID()}` },
    });
    await api.call('POST', '/v1/consents', { token, body: decision('health_data', 'granted', { sourceId: HC, scopes: ['steps'] }) });
    await api.call('POST', '/v1/consents', { token, body: decision('device_usage', 'granted') });
    await samples.importSample(tokens.userId, stepsSample(hc.id));
    await samples.importSample(tokens.userId, stepsSample(synthetic.id));
    await usage.importBucket(tokens.userId, usageBucket(tokens.deviceId));

    const withdrawal = await api.call('POST', '/v1/consents', {
      token,
      body: decision('health_data', 'revoked', { sourceId: HC, deleteCollectedData: true }),
    });
    assert.equal(withdrawal.status, 201);
    assert.equal(withdrawal.body['deletedRecords'], 1);
    assert.equal(await prisma.healthSample.count({ where: { userId: tokens.userId, dataSourceId: hc.id } }), 0);
    assert.equal(await prisma.healthSample.count({ where: { userId: tokens.userId, dataSourceId: synthetic.id } }), 1);
    assert.equal(await prisma.deviceUsageBucket.count({ where: { userId: tokens.userId } }), 1);
    assert.ok((await prisma.healthDataSource.findUniqueOrThrow({ where: { id: hc.id } })).deletedAtUtc);

    const usageWithdrawal = await api.call('POST', '/v1/consents', {
      token,
      body: decision('device_usage', 'revoked', { deleteCollectedData: true }),
    });
    assert.equal(usageWithdrawal.body['deletedRecords'], 1);
    assert.equal(await prisma.deviceUsageBucket.count({ where: { userId: tokens.userId } }), 0);

    const history = await api.call<Array<{ type: string; state: string }>>('GET', '/v1/consents/history', { token });
    assert.deepEqual(
      history.body.map((entry) => `${entry.type}:${entry.state}`),
      ['device_usage:revoked', 'health_data:revoked', 'device_usage:granted', 'health_data:granted'],
    );
    assert.equal(await prisma.auditEvent.count({ where: { userId: tokens.userId, action: 'data_deleted' } }), 2);
  });

  it('never shows one user\'s consents to another', async () => {
    const alice = await user();
    const bob = await user();
    await api.call('POST', '/v1/consents', { token: alice.accessToken, body: decision('analytics', 'granted') });
    const bobHistory = await api.call<unknown[]>('GET', '/v1/consents/history', { token: bob.accessToken });
    assert.deepEqual(bobHistory.body, []);
    assert.equal((await statusOf(bob.accessToken, 'analytics'))?.status, 'not_asked');
  });
});
