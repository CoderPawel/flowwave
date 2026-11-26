import { IdempotencyConflictError, ValidationError } from '../errors.js';
import { assertNoForbiddenFields } from '../privacy/forbiddenData.js';
import { parseZonedTimestamp, type ZonedTimestamp } from '../time/zonedTimestamp.js';

export type SyncOperationKind = 'upsert' | 'delete';

/**
 * A single change produced on a device and replayed on the server.
 * See docs/architecture/0004-offline-first-idempotent-sync.md.
 */
export interface SyncOperation<P = unknown> {
  /** Client-generated UUID; the idempotency key. */
  readonly operationId: string;
  readonly entityType: string;
  /** Client-generated UUID of the entity being changed. */
  readonly entityId: string;
  readonly kind: SyncOperationKind;
  readonly payload: P;
  /** Entity version the change was based on; `null` when creating. */
  readonly baseVersion: number | null;
  readonly createdAt: ZonedTimestamp;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const ENTITY_TYPE = /^[a-z][a-z0-9_]{0,62}$/;

export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && UUID.test(value);
}

/** Validates an operation received over the network before it is applied. */
export function parseSyncOperation(value: unknown): SyncOperation {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new ValidationError('operation', 'Expected an object.');
  }
  const op = value as Record<string, unknown>;

  if (!isUuid(op.operationId)) {
    throw new ValidationError('operationId', 'Expected a UUID.');
  }
  if (typeof op.entityType !== 'string' || !ENTITY_TYPE.test(op.entityType)) {
    throw new ValidationError('entityType', 'Expected a snake_case entity type.');
  }
  if (!isUuid(op.entityId)) {
    throw new ValidationError('entityId', 'Expected a UUID.');
  }
  if (op.kind !== 'upsert' && op.kind !== 'delete') {
    throw new ValidationError('kind', 'Expected "upsert" or "delete".');
  }
  if (
    op.baseVersion !== null &&
    !(typeof op.baseVersion === 'number' && Number.isInteger(op.baseVersion) && op.baseVersion >= 0)
  ) {
    throw new ValidationError('baseVersion', 'Expected a non-negative integer or null.');
  }
  if (op.kind === 'delete' && op.baseVersion === null) {
    throw new ValidationError('baseVersion', 'Deleting requires the version being deleted.');
  }
  if (!('payload' in op)) {
    throw new ValidationError('payload', 'Payload is required (use null for deletes).');
  }
  assertNoForbiddenFields(op.payload);

  return {
    operationId: op.operationId.toLowerCase(),
    entityType: op.entityType,
    entityId: op.entityId.toLowerCase(),
    kind: op.kind,
    payload: op.payload,
    baseVersion: op.baseVersion,
    createdAt: parseZonedTimestamp(op.createdAt),
  };
}

/** Deterministic JSON with object keys sorted, used to compare payloads. */
export function canonicalJson(value: unknown): string {
  const serialize = (v: unknown, path: string): string => {
    if (v === null) return 'null';
    switch (typeof v) {
      case 'string':
      case 'boolean':
        return JSON.stringify(v);
      case 'number':
        if (!Number.isFinite(v)) {
          throw new ValidationError(path || 'value', 'Non-finite numbers cannot be synchronized.');
        }
        return JSON.stringify(v);
      case 'object': {
        if (Array.isArray(v)) {
          return `[${v.map((item, i) => serialize(item, `${path}[${i}]`)).join(',')}]`;
        }
        const entries = Object.entries(v as Record<string, unknown>)
          .filter(([, child]) => child !== undefined)
          .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
          .map(([key, child]) => `${JSON.stringify(key)}:${serialize(child, path ? `${path}.${key}` : key)}`);
        return `{${entries.join(',')}}`;
      }
      default:
        throw new ValidationError(path || 'value', `Values of type ${typeof v} cannot be synchronized.`);
    }
  };
  return serialize(value, '');
}

/**
 * Identifies the change an operation makes. `createdAt` is metadata and is
 * excluded so a retried operation always matches its first delivery.
 */
export function operationFingerprint(op: SyncOperation): string {
  return canonicalJson({
    entityType: op.entityType,
    entityId: op.entityId,
    kind: op.kind,
    baseVersion: op.baseVersion,
    payload: op.payload,
  });
}

export interface AppliedOperationRecord<R> {
  readonly operationId: string;
  readonly fingerprint: string;
  readonly result: R;
}

/**
 * Persistence for applied operations. Server implementations must run
 * `applyIdempotently` inside one database transaction so the change and its
 * record commit together.
 */
export interface AppliedOperationStore<R> {
  get(operationId: string): Promise<AppliedOperationRecord<R> | undefined>;
  put(record: AppliedOperationRecord<R>): Promise<void>;
}

export type IdempotentOutcome<R> =
  | { readonly status: 'applied'; readonly result: R }
  | { readonly status: 'replayed'; readonly result: R };

export async function applyIdempotently<P, R>(
  op: SyncOperation<P>,
  store: AppliedOperationStore<R>,
  apply: (op: SyncOperation<P>) => R | Promise<R>,
): Promise<IdempotentOutcome<R>> {
  const fingerprint = operationFingerprint(op);
  const existing = await store.get(op.operationId);
  if (existing) {
    if (existing.fingerprint !== fingerprint) {
      throw new IdempotencyConflictError(op.operationId);
    }
    return { status: 'replayed', result: existing.result };
  }
  const result = await apply(op);
  await store.put({ operationId: op.operationId, fingerprint, result });
  return { status: 'applied', result };
}

export class InMemoryAppliedOperationStore<R> implements AppliedOperationStore<R> {
  readonly #records = new Map<string, AppliedOperationRecord<R>>();

  async get(operationId: string): Promise<AppliedOperationRecord<R> | undefined> {
    return this.#records.get(operationId);
  }

  async put(record: AppliedOperationRecord<R>): Promise<void> {
    const existing = this.#records.get(record.operationId);
    if (existing && existing.fingerprint !== record.fingerprint) {
      throw new IdempotencyConflictError(record.operationId);
    }
    if (!existing) {
      this.#records.set(record.operationId, record);
    }
  }
}
