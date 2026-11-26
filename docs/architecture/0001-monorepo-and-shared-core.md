# 0001. Monorepo with a dependency-free shared core

- Status: Accepted
- Date: 2026-11-26

## Context

FlowWave will have an offline-first mobile app and a synchronization API. Both
must agree exactly on the domain rules: how timestamps are stored, how missing
data is represented, when consent is required, how sync operations are
deduplicated, and how scores and their explanations are calculated. Duplicating
these rules per client is the most likely way to break the project principles.

## Decision

- One repository using npm workspaces. Packages live in `packages/*`.
- The first package is `@flowwave/core`: pure TypeScript domain logic with
  **zero runtime dependencies**, so it can run unchanged in React Native, Node,
  and tests. It uses only ECMAScript built-ins (`Intl` for time zones).
- Future packages (`apps/mobile`, `apps/api`) consume `@flowwave/core` and each
  gets its own decision note before it is added, including its framework choice.
- PostgreSQL is the planned server store; schema changes are plain SQL
  migrations in `db/migrations`, applied in numeric order. A migration runner
  is deliberately not chosen yet; it will be picked together with the API.

## Dependencies

Development only:

- `typescript` — compiler and strict type checker; the project is written in TypeScript.
- `@types/node` — type definitions for the built-in `node:test` runner and
  `node:assert`, which are used instead of a third-party test framework.

No linter or test framework is added yet: `tsc --strict` with unused-code checks
and the built-in Node test runner cover the current needs without extra
dependencies.

## Consequences

- Domain rules are tested once and shared.
- The core cannot use Node-only APIs (`fs`, `crypto`), which keeps it portable
  but means hashing or storage must be injected by the host app.
