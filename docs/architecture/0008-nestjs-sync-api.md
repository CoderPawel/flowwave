# 0008. NestJS for the sync API

- Status: Accepted (platform choice). Authentication and hosting get their own decision notes before the API phase.
- Date: 2026-11-27

## Context

FlowWave needs a server for opt-in backup and sync now, and as the backend for
the Next.js web panel, iOS app, and Windows agent later. Sync rules
(idempotency, payload validation, privacy guard) already exist in
`@flowwave/core`, written in TypeScript. The owner chose NestJS.

## Decision

- The sync API is a NestJS application in `apps/api`, running on Node.js 22+
  and importing `@flowwave/core` for validation, idempotency, and the privacy
  guard.
- PostgreSQL access uses the `pg` driver with parameterized SQL; schema changes
  stay as plain SQL files in `db/migrations`. An ORM is not added in the MVP:
  the schema relies on PostgreSQL constraints and triggers that are clearer in
  SQL. A migration runner is chosen in the API phase.
- MVP endpoints (all versioned under `/v1`, all scoped to the authenticated
  user):

  | Endpoint | Purpose |
  | --- | --- |
  | `POST /v1/sync/operations` | Apply a batch of operations idempotently; returns `applied`, `replayed`, or an error per operation |
  | `GET /v1/sync/changes?cursor=` | Changes since a cursor, for restoring a device |
  | `GET /v1/export` | All of the user's server data as JSON |
  | `DELETE /v1/account` | Delete the account and all server data |
  | `GET /v1/health` | Liveness check without user data |

- Each operation is applied and recorded in `applied_sync_operations` in one
  transaction. The user ID comes from the access token, never from the payload.
- Requests carrying forbidden fields are rejected with the core error code
  `forbidden_data`; validation errors return `validation_failed`.

## Dependencies (added in the API phase)

| Dependency | Why it is required |
| --- | --- |
| `@nestjs/core`, `@nestjs/common`, `@nestjs/platform-express` | The chosen framework: modules, dependency injection, request pipeline, testing utilities. |
| `pg` | PostgreSQL driver; required to talk to the database. |

Authentication libraries are justified in the authentication decision note.

## Consequences

- One language (TypeScript) for core rules and the server; the core runs
  unchanged on the server.
- NestJS adds framework weight compared with a minimal HTTP server, in exchange
  for structure that will carry the web panel and later clients.
- The Android app remains fully functional without the API.

## Acceptance criteria

- Sending the same operation batch twice produces identical responses and no
  extra rows (integration test against PostgreSQL in CI).
- An operation with forbidden fields is rejected and nothing is stored (test).
- A user can never read or change another user's rows (test).
- `DELETE /v1/account` leaves no rows for the user in any table (test).
