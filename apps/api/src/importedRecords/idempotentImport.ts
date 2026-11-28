import { randomUUID } from 'node:crypto';
import { IdempotencyConflictError } from '@flowwave/core';
import { withDatabaseErrors } from '../prisma/databaseErrors.js';

/**
 * Result of importing one record:
 * - `inserted`: the record was new;
 * - `unchanged`: an identical record was already stored (a retried import);
 * - `updated`: the source changed the record since it was stored;
 * - `stale`: a newer version is already stored, so the incoming one was ignored.
 */
export type ImportOutcome = 'inserted' | 'unchanged' | 'updated' | 'stale';

export interface ImportResult {
  readonly outcome: ImportOutcome;
  readonly id: string;
}

/**
 * Decides what to do when a record with the same import identity already
 * exists. The source's modification time orders versions; the same
 * modification time with different content means the source broke its own
 * contract, which is reported instead of silently picking one version.
 */
export function decideExistingImport(params: {
  readonly idempotencyKey: string;
  readonly sameContent: boolean;
  readonly storedSourceUpdatedAt: Date;
  readonly incomingSourceUpdatedAt: Date;
}): 'unchanged' | 'update' | 'stale' {
  if (params.sameContent) {
    return 'unchanged';
  }
  const stored = params.storedSourceUpdatedAt.getTime();
  const incoming = params.incomingSourceUpdatedAt.getTime();
  if (incoming > stored) {
    return 'update';
  }
  if (incoming < stored) {
    return 'stale';
  }
  throw new IdempotencyConflictError(params.idempotencyKey);
}

/** Compares column values as stored by Prisma: dates by instant, everything else strictly. */
export function sameColumnValues(stored: Readonly<Record<string, unknown>>, incoming: Readonly<Record<string, unknown>>): boolean {
  return Object.entries(incoming).every(([column, value]) => {
    const current = stored[column];
    if (value instanceof Date || current instanceof Date) {
      return value instanceof Date && current instanceof Date && value.getTime() === current.getTime();
    }
    return current === value;
  });
}

export interface IdempotentImportSteps<Row extends { readonly id: string; readonly sourceUpdatedAtUtc: Date }> {
  readonly idempotencyKey: string;
  readonly sourceUpdatedAt: Date;
  /** Columns that make up the record's content; compared to detect retries. */
  readonly content: Readonly<Record<string, unknown>>;
  /** INSERT ... ON CONFLICT DO NOTHING with the given id; resolves to the number of inserted rows. */
  readonly insert: (id: string) => Promise<number>;
  /** Finds the stored row that blocked the insert, by any of the table's unique import keys. */
  readonly findExisting: () => Promise<Row | null>;
  /** Updates the row only if its stored source time is older; resolves to the number of updated rows. */
  readonly updateIfOlder: (id: string) => Promise<number>;
}

/**
 * Inserts a record exactly once, safe under retries and concurrent imports:
 * the database's unique constraints decide which insert wins, and updates are
 * conditional on the stored version being older.
 */
export async function importIdempotently<Row extends { readonly id: string; readonly sourceUpdatedAtUtc: Date }>(
  steps: IdempotentImportSteps<Row>,
): Promise<ImportResult> {
  const id = randomUUID();
  if ((await withDatabaseErrors(() => steps.insert(id))) === 1) {
    return { outcome: 'inserted', id };
  }
  const existing = await steps.findExisting();
  if (!existing) {
    throw new Error(`Import of "${steps.idempotencyKey}" conflicted with a row that no longer exists; retry the import.`);
  }
  const decision = decideExistingImport({
    idempotencyKey: steps.idempotencyKey,
    sameContent: sameColumnValues(existing, steps.content),
    storedSourceUpdatedAt: existing.sourceUpdatedAtUtc,
    incomingSourceUpdatedAt: steps.sourceUpdatedAt,
  });
  if (decision !== 'update') {
    return { outcome: decision, id: existing.id };
  }
  const updated = await withDatabaseErrors(() => steps.updateIfOlder(existing.id));
  return { outcome: updated === 1 ? 'updated' : 'stale', id: existing.id };
}
