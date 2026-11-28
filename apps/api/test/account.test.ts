import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { after, before, describe, it } from 'node:test';
import type { INestApplication } from '@nestjs/common';
import { createZonedTimestamp, CURRENT_CONSENT_POLICY_VERSIONS } from '@flowwave/core';
import { DataExportService, EXPORTED_TABLES, EXPORT_FORMAT } from '../src/account/dataExportService.js';
import { DeviceUsageBucketRepository } from '../src/importedRecords/deviceUsageBucketRepository.js';
import { HealthSampleRepository } from '../src/importedRecords/healthSampleRepository.js';
import { RetentionService } from '../src/maintenance/retentionService.js';
import { PrismaService } from '../src/prisma/prismaService.js';
import { apiClient, TEST_PASSWORD } from './support/apiClient.js';
import { startTestApp, TEST_CONFIG } from './support/testApp.js';

const databaseUrl = process.env['FLOWWAVE_TEST_DATABASE_URL'];
const DAY_MS = 86_400_000;

interface ExportJob {
  id: string;
  status: string;
  expiresAt: string | null;
}

interface ExportFile {
  format: string;
  formatVersion: number;
  userId: string;
  notice: string;
  omittedColumns: string[];
  tables: Record<string, Array<Record<string, unknown>>>;
}

describe('account export and deletion against PostgreSQL', { skip: !databaseUrl }, () => {
  const config = { ...TEST_CONFIG, databaseUrl: databaseUrl! };
  let app: INestApplication;
  let api: ReturnType<typeof apiClient>;
  let prisma: PrismaService;
  let exports: DataExportService;
  const userIds: string[] = [];

  async function user() {
    const registered = await api.register();
    userIds.push(registered.tokens.userId);
    return registered;
  }

  async function tablesWithUserId(): Promise<string[]> {
    const rows = await prisma.$queryRaw<Array<{ table_name: string }>>`
      SELECT table_name FROM information_schema.columns
      WHERE table_schema = 'public' AND column_name = 'user_id'
      ORDER BY table_name`;
    return rows.map((row) => row.table_name);
  }

  /** Gives the user a little of everything: consent, a usage bucket, and a step count. */
  async function addData(userId: string, deviceId: string) {
    await api.call('POST', '/v1/consents', {
      token: (await api.login((await prisma.userCredential.findUniqueOrThrow({ where: { userId } })).email)).body['accessToken'] as string,
      body: {
        id: randomUUID(),
        type: 'device_usage',
        state: 'granted',
        scopes: [],
        policyVersion: CURRENT_CONSENT_POLICY_VERSIONS.device_usage,
        decidedAt: createZonedTimestamp('2026-11-27T08:00:00Z', 'Europe/Budapest'),
      },
    });
    await app.get(DeviceUsageBucketRepository).importBucket(userId, {
      deviceId,
      bucketStart: createZonedTimestamp('2026-11-26T08:00:00Z', 'Europe/Budapest'),
      metrics: { status: 'missing', reason: 'source_unavailable' },
      sourceUpdatedAt: new Date('2026-11-26T09:00:00Z'),
      idempotencyKey: `usage:${randomUUID()}`,
    });
    const source = await prisma.healthDataSource.create({
      data: { userId, kind: 'synthetic', sourceKey: `synthetic:${randomUUID()}` },
    });
    await app.get(HealthSampleRepository).importSample(userId, {
      dataSourceId: source.id,
      metric: 'steps',
      start: createZonedTimestamp('2026-11-26T07:00:00Z', 'Europe/Budapest'),
      end: createZonedTimestamp('2026-11-26T08:00:00Z', 'Europe/Budapest'),
      value: { status: 'present', value: 4321 },
      sourceUpdatedAt: new Date('2026-11-26T08:05:00Z'),
      idempotencyKey: `steps:${randomUUID()}`,
    });
  }

  before(async () => {
    const started = await startTestApp(config);
    app = started.app;
    api = apiClient(started.baseUrl);
    prisma = new PrismaService(config);
    exports = app.get(DataExportService);
  });

  after(async () => {
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('exports every table that holds user data', async () => {
    assert.deepEqual([...EXPORTED_TABLES].sort(), [...(await tablesWithUserId()), 'users'].sort());
  });

  it('queues one export at a time and completes it in the background worker', async () => {
    const { tokens } = await user();
    const first = await api.call<ExportJob>('POST', '/v1/account/exports', { token: tokens.accessToken });
    assert.equal(first.status, 202);
    assert.equal(first.body.status, 'pending');
    const again = await api.call<ExportJob>('POST', '/v1/account/exports', { token: tokens.accessToken });
    assert.equal(again.status, 200);
    assert.equal(again.body.id, first.body.id);

    const notReady = await api.call('GET', `/v1/account/exports/${first.body.id}/download`, { token: tokens.accessToken });
    assert.equal(notReady.status, 409);

    while ((await exports.processPending()) > 0);
    const done = await api.call<ExportJob>('GET', `/v1/account/exports/${first.body.id}`, { token: tokens.accessToken });
    assert.equal(done.body.status, 'completed');
    const expiresInDays = (Date.parse(done.body.expiresAt ?? '') - Date.now()) / DAY_MS;
    assert.ok(expiresInDays > 6.9 && expiresInDays <= 7, 'the file is kept for 7 days');
  });

  it('contains the user\'s rows, no secrets, and nothing of other users', async () => {
    const { tokens, email } = await user();
    const { tokens: other } = await user();
    await addData(tokens.userId, tokens.deviceId);
    await addData(other.userId, other.deviceId);

    const job = await api.call<ExportJob>('POST', '/v1/account/exports', { token: tokens.accessToken });
    while ((await exports.processPending()) > 0);
    const download = await api.call<ExportFile>('GET', `/v1/account/exports/${job.body.id}/download`, { token: tokens.accessToken });
    assert.equal(download.status, 200);
    assert.equal(download.headers.get('cache-control'), 'no-store');
    assert.match(download.headers.get('content-disposition') ?? '', /attachment/);

    const file = download.body;
    assert.equal(file.format, EXPORT_FORMAT);
    assert.equal(file.formatVersion, 1);
    assert.match(file.notice, /not medical diagnoses/);
    assert.deepEqual(file.tables['users']?.map((row) => row['id']), [tokens.userId]);
    assert.equal(file.tables['user_credentials']?.[0]?.['email'], email);
    assert.equal(file.tables['health_samples']?.[0]?.['value'], 4321);
    assert.equal(file.tables['device_usage_buckets']?.[0]?.['missing_reason'], 'source_unavailable');
    assert.ok(file.tables['consent_decisions']?.some((row) => row['consent_type'] === 'device_usage'));
    assert.equal(file.tables['auth_sessions']?.length, 2, 'registration and the extra sign-in');

    for (const [table, rows] of Object.entries(file.tables)) {
      for (const row of rows) {
        assert.equal(table === 'users' ? row['id'] : row['user_id'], tokens.userId, `${table} holds only this user's rows`);
      }
    }
    const text = JSON.stringify(file);
    assert.equal(text.includes(other.userId), false);
    assert.equal(text.includes('$argon2id$'), false);
    assert.equal(/"(password_hash|access_token_hash|refresh_token_hash)"/.test(text), false);
    assert.equal(text.includes(tokens.accessToken), false);
    assert.deepEqual(file.omittedColumns.sort(), [
      'auth_tokens.access_token_hash',
      'auth_tokens.refresh_token_hash',
      'data_export_jobs.result',
      'user_credentials.password_hash',
    ]);

    assert.equal(await prisma.auditEvent.count({ where: { userId: tokens.userId, action: 'data_export_requested' } }), 1);
    assert.equal(await prisma.auditEvent.count({ where: { userId: tokens.userId, action: 'data_exported' } }), 1);
    const foreign = await api.call('GET', `/v1/account/exports/${job.body.id}/download`, { token: other.accessToken });
    assert.equal(foreign.status, 404);
  });

  it('refuses expired downloads and drops the file in retention', async () => {
    const { tokens } = await user();
    const job = await api.call<ExportJob>('POST', '/v1/account/exports', { token: tokens.accessToken });
    while ((await exports.processPending()) > 0);
    await prisma.dataExportJob.update({ where: { id: job.body.id }, data: { expiresAtUtc: new Date(Date.now() - 1000) } });

    const expired = await api.call('GET', `/v1/account/exports/${job.body.id}/download`, { token: tokens.accessToken });
    assert.equal(expired.status, 409);
    await app.get(RetentionService).run();
    const row = await prisma.dataExportJob.findUniqueOrThrow({ where: { id: job.body.id } });
    assert.equal(row.status, 'expired');
    assert.equal(row.result, null);
  });

  it('marks exports interrupted by a restart as failed', async () => {
    const { tokens } = await user();
    const job = await prisma.dataExportJob.create({
      data: { userId: tokens.userId, status: 'running', startedAtUtc: new Date(Date.now() - 2 * 3_600_000) },
    });
    await app.get(RetentionService).run();
    const row = await prisma.dataExportJob.findUniqueOrThrow({ where: { id: job.id } });
    assert.equal(row.status, 'failed');
    assert.equal(row.failureCode, 'export_interrupted');
  });

  it('removes ended sessions after 30 days and tombstones after 90 days', async () => {
    const { tokens } = await user();
    const device = await prisma.device.create({ data: { userId: tokens.userId, platform: 'web' } });
    const old = await prisma.authSession.create({
      data: {
        userId: tokens.userId,
        deviceId: device.id,
        createdAtUtc: new Date(Date.now() - 60 * DAY_MS),
        expiresAtUtc: new Date(Date.now() - 31 * DAY_MS),
        revokedAtUtc: new Date(Date.now() - 31 * DAY_MS),
        revokedReason: 'logout',
      },
    });
    await addData(tokens.userId, tokens.deviceId);
    const sample = await prisma.healthSample.findFirstOrThrow({ where: { userId: tokens.userId } });
    await prisma.healthSample.update({ where: { id: sample.id }, data: { deletedAtUtc: new Date(Date.now() - 91 * DAY_MS) } });

    const report = await app.get(RetentionService).run();
    assert.ok(report.sessionsDeleted >= 1);
    assert.equal(await prisma.authSession.count({ where: { id: old.id } }), 0);
    assert.equal(await prisma.authSession.count({ where: { id: tokens.sessionId } }), 1, 'active sessions stay');
    assert.equal(await prisma.healthSample.count({ where: { id: sample.id } }), 0);
    assert.equal(await prisma.device.count({ where: { id: device.id } }), 1, 'devices stay');
  });

  it('deletes the account only with the password, leaving no row with its ID', async () => {
    const { tokens } = await user();
    await addData(tokens.userId, tokens.deviceId);
    await api.call('POST', '/v1/account/exports', { token: tokens.accessToken });

    const wrong = await api.call('DELETE', '/v1/account', { token: tokens.accessToken, body: { password: 'not my password' } });
    assert.equal(wrong.status, 403);
    assert.equal(wrong.body['reason'], 'reauthentication_failed');
    assert.equal(await prisma.user.count({ where: { id: tokens.userId } }), 1);

    const deleted = await api.call('DELETE', '/v1/account', { token: tokens.accessToken, body: { password: TEST_PASSWORD } });
    assert.equal(deleted.status, 200);
    const receiptId = deleted.body['receiptId'] as string;

    for (const table of await tablesWithUserId()) {
      const rows = await prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
        `SELECT count(*) AS count FROM "${table}" WHERE user_id = $1::uuid`,
        tokens.userId,
      );
      assert.equal(Number(rows[0]?.count), 0, `${table} has no rows of the deleted user`);
    }
    assert.equal(await prisma.user.count({ where: { id: tokens.userId } }), 0);
    const receipt = await prisma.auditEvent.findUniqueOrThrow({ where: { id: receiptId } });
    assert.equal(receipt.action, 'account_deleted');
    assert.equal(receipt.userId, null);
    assert.equal(JSON.stringify(receipt).includes(tokens.userId), false);
    assert.ok((await prisma.auditEvent.count({ where: { userId: null, action: 'account_created' } })) >= 1, 'older audit events stay, detached');

    assert.equal((await api.call('GET', '/v1/account', { token: tokens.accessToken })).status, 401);
  });
});
