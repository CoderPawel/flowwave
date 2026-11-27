# 0004. Offline-first storage with idempotent sync operations

- Status: Accepted
- Date: 2026-11-26

## Context

The mobile app must work fully offline and synchronize later over unreliable
networks. Retries, duplicate deliveries, and app restarts mid-sync are normal,
so applying the same change twice must have the same effect as applying it once.

## Decision

- The device is the primary writer. Every local change is written to the local
  store and to an outbox as a `SyncOperation` with a client-generated
  `operationId` (UUID) and a client-generated `entityId`.
- The server keeps an `applied_sync_operations` table keyed by `operationId`
  with a canonical payload fingerprint and the stored result.
- `applyIdempotently` semantics:
  - unseen `operationId` → apply and record the result atomically;
  - seen `operationId` with the same fingerprint → return the stored result
    without re-applying;
  - seen `operationId` with a different fingerprint → `IdempotencyConflictError`.
- Entities carry a monotonically increasing `version`; an operation's
  `baseVersion` enables optimistic concurrency. Deletes are soft (tombstones)
  so they sync like any other change.

## Consequences

- Clients can retry blindly; the server is safe against duplicates.
- The server must apply the change and record the operation in one database
  transaction.
- Conflict-resolution policy beyond version checks is deferred to the API
  decision note.
