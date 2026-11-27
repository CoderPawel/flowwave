import assert from 'node:assert/strict';
import { after, before, describe, it } from 'node:test';
import type { INestApplication } from '@nestjs/common';
import { DatabaseHealth } from '../src/health/databaseHealth.js';
import { pathOnly } from '../src/logging/loggerOptions.js';
import type { PrismaService } from '../src/prisma/prismaService.js';
import { startTestApp, TEST_CONFIG } from './support/testApp.js';

describe('health endpoints', () => {
  let app: INestApplication;
  let baseUrl: string;
  let databaseUp = true;

  before(async () => {
    ({ app, baseUrl } = await startTestApp(TEST_CONFIG, [
      { provide: DatabaseHealth, useValue: { isUp: async () => databaseUp } },
    ]));
  });

  after(async () => {
    await app.close();
  });

  it('reports liveness without touching the database', async () => {
    databaseUp = false;
    const response = await fetch(`${baseUrl}/v1/health`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok' });
  });

  it('reports readiness when the database is reachable', async () => {
    databaseUp = true;
    const response = await fetch(`${baseUrl}/v1/health/ready`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: 'ok', checks: { database: 'up' } });
  });

  it('returns 503 without error details when the database is down', async () => {
    databaseUp = false;
    const response = await fetch(`${baseUrl}/v1/health/ready`);
    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), { status: 'unavailable', checks: { database: 'down' } });
  });

  it('echoes a valid request id and replaces an invalid one', async () => {
    const id = '0b7e6a52-3c1f-4d7e-9a3b-2f8c1d4e5a6b';
    const echoed = await fetch(`${baseUrl}/v1/health`, { headers: { 'x-request-id': id } });
    assert.equal(echoed.headers.get('x-request-id'), id);
    const replaced = await fetch(`${baseUrl}/v1/health`, { headers: { 'x-request-id': 'drop table users' } });
    assert.match(replaced.headers.get('x-request-id') ?? '', /^[0-9a-f-]{36}$/);
  });

  it('serves the OpenAPI document when Swagger is enabled', async () => {
    const response = await fetch(`${baseUrl}/docs/openapi.json`);
    assert.equal(response.status, 200);
    const document = (await response.json()) as { info: { title: string }; paths: Record<string, unknown> };
    assert.equal(document.info.title, 'FlowWave API');
    assert.ok('/v1/health' in document.paths);
    assert.ok('/v1/health/ready' in document.paths);
  });

  it('returns 404 for unknown routes', async () => {
    const response = await fetch(`${baseUrl}/v1/does-not-exist`);
    assert.equal(response.status, 404);
  });
});

describe('DatabaseHealth', () => {
  it('is down when the query fails or exceeds the timeout', async () => {
    const failing = new DatabaseHealth({ $queryRaw: () => Promise.reject(new Error('connection refused')) } as unknown as PrismaService);
    assert.equal(await failing.isUp(50), false);

    const hanging = new DatabaseHealth({ $queryRaw: () => new Promise(() => undefined) } as unknown as PrismaService);
    assert.equal(await hanging.isUp(20), false);

    const healthy = new DatabaseHealth({ $queryRaw: () => Promise.resolve([{ '?column?': 1 }]) } as unknown as PrismaService);
    assert.equal(await healthy.isUp(50), true);
  });
});

describe('pathOnly', () => {
  it('strips query strings and fragments before logging', () => {
    assert.equal(pathOnly('/v1/sync/changes?cursor=abc&token=secret'), '/v1/sync/changes');
    assert.equal(pathOnly('/v1/health#x'), '/v1/health');
    assert.equal(pathOnly(undefined), '');
  });
});

describe('database readiness against PostgreSQL', { skip: !process.env['FLOWWAVE_TEST_DATABASE_URL'] }, () => {
  it('is ready with a real database and unavailable with an unreachable one', async () => {
    const real = await startTestApp({ ...TEST_CONFIG, databaseUrl: process.env['FLOWWAVE_TEST_DATABASE_URL']! });
    try {
      const response = await fetch(`${real.baseUrl}/v1/health/ready`);
      assert.equal(response.status, 200);
    } finally {
      await real.app.close();
    }

    const unreachable = await startTestApp(TEST_CONFIG);
    try {
      const response = await fetch(`${unreachable.baseUrl}/v1/health/ready`);
      assert.equal(response.status, 503);
    } finally {
      await unreachable.app.close();
    }
  });
});
