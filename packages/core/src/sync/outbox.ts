import { IdempotencyConflictError } from '../errors.js';
import { compareZonedTimestamps } from '../time/zonedTimestamp.js';
import { operationFingerprint, type SyncOperation } from './syncOperation.js';

/**
 * Device-side queue of changes waiting to be synchronized. Local writes go to
 * the local store and the outbox together, so the app works fully offline.
 */
export interface SyncOutbox {
  /** Adds an operation. Re-enqueueing the same operation is a no-op. */
  enqueue(op: SyncOperation): Promise<void>;
  /** Pending operations, oldest first. */
  pending(limit?: number): Promise<readonly SyncOperation[]>;
  /** Removes operations the server confirmed (applied or replayed). Unknown IDs are ignored. */
  acknowledge(operationIds: readonly string[]): Promise<void>;
}

export class InMemorySyncOutbox implements SyncOutbox {
  readonly #operations = new Map<string, SyncOperation>();

  async enqueue(op: SyncOperation): Promise<void> {
    const existing = this.#operations.get(op.operationId);
    if (existing) {
      if (operationFingerprint(existing) !== operationFingerprint(op)) {
        throw new IdempotencyConflictError(op.operationId);
      }
      return;
    }
    this.#operations.set(op.operationId, op);
  }

  async pending(limit?: number): Promise<readonly SyncOperation[]> {
    const ordered = [...this.#operations.values()].sort((a, b) =>
      compareZonedTimestamps(a.createdAt, b.createdAt),
    );
    return limit === undefined ? ordered : ordered.slice(0, Math.max(0, limit));
  }

  async acknowledge(operationIds: readonly string[]): Promise<void> {
    for (const id of operationIds) {
      this.#operations.delete(id);
    }
  }
}
