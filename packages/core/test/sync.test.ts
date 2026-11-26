import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  ForbiddenDataError,
  IdempotencyConflictError,
  InMemoryAppliedOperationStore,
  InMemorySyncOutbox,
  ValidationError,
  applyIdempotently,
  canonicalJson,
  createZonedTimestamp,
  operationFingerprint,
  parseSyncOperation,
  type SyncOperation,
} from '../src/index.js';

const OP_ID = '0b7e6a52-3c1f-4d7e-9a3b-2f8c1d4e5a6b';
const ENTITY_ID = '6f1c2d3e-4b5a-4c6d-8e7f-9a0b1c2d3e4f';

function operation(overrides: Partial<SyncOperation> = {}): SyncOperation {
  return {
    operationId: OP_ID,
    entityType: 'check_in',
    entityId: ENTITY_ID,
    kind: 'upsert',
    payload: { selfReportedEnergy: 4 },
    baseVersion: null,
    createdAt: createZonedTimestamp('2026-11-26T16:00:00Z', 'Europe/Budapest'),
    ...overrides,
  };
}

describe('canonicalJson', () => {
  it('is independent of key order and drops undefined properties', () => {
    assert.equal(canonicalJson({ b: 1, a: { d: [1, 2], c: undefined } }), canonicalJson({ a: { d: [1, 2] }, b: 1 }));
  });

  it('rejects values that cannot be represented faithfully', () => {
    assert.throws(() => canonicalJson({ value: Number.NaN }), ValidationError);
    assert.throws(() => canonicalJson({ value: 1n }), ValidationError);
    assert.throws(() => canonicalJson({ fn: () => 1 }), ValidationError);
  });
});

describe('applyIdempotently', () => {
  it('applies a new operation exactly once and replays the stored result', async () => {
    const store = new InMemoryAppliedOperationStore<{ version: number }>();
    let applyCount = 0;
    const apply = () => ({ version: ++applyCount });

    const first = await applyIdempotently(operation(), store, apply);
    const retry = await applyIdempotently(operation(), store, apply);

    assert.deepEqual(first, { status: 'applied', result: { version: 1 } });
    assert.deepEqual(retry, { status: 'replayed', result: { version: 1 } });
    assert.equal(applyCount, 1);
  });

  it('treats a retry with a new createdAt or reordered keys as the same operation', async () => {
    const store = new InMemoryAppliedOperationStore<string>();
    await applyIdempotently(operation({ payload: { a: 1, b: 2 } }), store, () => 'ok');
    const retry = await applyIdempotently(
      operation({
        payload: { b: 2, a: 1 },
        createdAt: createZonedTimestamp('2026-11-26T18:00:00Z', 'UTC'),
      }),
      store,
      () => assert.fail('must not re-apply'),
    );
    assert.equal(retry.status, 'replayed');
  });

  it('rejects a reused operation id with a different payload', async () => {
    const store = new InMemoryAppliedOperationStore<string>();
    await applyIdempotently(operation(), store, () => 'ok');
    await assert.rejects(
      applyIdempotently(operation({ payload: { selfReportedEnergy: 2 } }), store, () => 'changed'),
      IdempotencyConflictError,
    );
  });

  it('records nothing when applying fails, so the client can retry', async () => {
    const store = new InMemoryAppliedOperationStore<string>();
    await assert.rejects(
      applyIdempotently(operation(), store, () => {
        throw new Error('database unavailable');
      }),
      /database unavailable/,
    );
    const retry = await applyIdempotently(operation(), store, () => 'ok');
    assert.equal(retry.status, 'applied');
  });
});

describe('parseSyncOperation', () => {
  const wire = () => JSON.parse(JSON.stringify(operation())) as Record<string, unknown>;

  it('accepts a valid operation and normalizes ids to lower case', () => {
    const raw = { ...wire(), operationId: OP_ID.toUpperCase() };
    const parsed = parseSyncOperation(raw);
    assert.equal(parsed.operationId, OP_ID);
    assert.equal(operationFingerprint(parsed), operationFingerprint(operation()));
  });

  it('validates every field', () => {
    const invalid: Array<Record<string, unknown>> = [
      { ...wire(), operationId: 'retry-1' },
      { ...wire(), entityId: 42 },
      { ...wire(), entityType: 'Check In' },
      { ...wire(), kind: 'merge' },
      { ...wire(), baseVersion: -1 },
      { ...wire(), kind: 'delete', baseVersion: null },
      { ...wire(), createdAt: '2026-11-26T16:00:00Z' },
    ];
    for (const raw of invalid) {
      assert.throws(() => parseSyncOperation(raw), ValidationError, JSON.stringify(raw));
    }
    const { payload: _payload, ...withoutPayload } = wire();
    assert.throws(() => parseSyncOperation(withoutPayload), ValidationError);
    assert.throws(() => parseSyncOperation([]), ValidationError);
  });

  it('refuses payloads with data FlowWave must never collect', () => {
    assert.throws(
      () => parseSyncOperation({ ...wire(), payload: { selfReportedEnergy: 3, windowTitle: 'Inbox' } }),
      ForbiddenDataError,
    );
  });
});

describe('InMemorySyncOutbox', () => {
  it('deduplicates, orders by creation time, and removes acknowledged operations', async () => {
    const outbox = new InMemorySyncOutbox();
    const later = operation({
      operationId: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      createdAt: createZonedTimestamp('2026-11-26T17:00:00Z', 'UTC'),
    });
    await outbox.enqueue(later);
    await outbox.enqueue(operation());
    await outbox.enqueue(operation());

    assert.deepEqual((await outbox.pending()).map((op) => op.operationId), [OP_ID, later.operationId]);
    assert.equal((await outbox.pending(1)).length, 1);

    await outbox.acknowledge([OP_ID, 'unknown-id']);
    assert.deepEqual((await outbox.pending()).map((op) => op.operationId), [later.operationId]);
  });

  it('rejects a different change queued under an existing operation id', async () => {
    const outbox = new InMemorySyncOutbox();
    await outbox.enqueue(operation());
    await assert.rejects(outbox.enqueue(operation({ payload: { selfReportedEnergy: 1 } })), IdempotencyConflictError);
  });
});
