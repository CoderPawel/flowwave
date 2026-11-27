# FlowWave

FlowWave is a privacy-first personal energy and focus rhythm application. It
helps people notice when they tend to have more or less energy and suggests
how to plan focused work. **It is not a medical application**, and its
estimates are not medical assessments or diagnoses.

Read [`AGENTS.md`](AGENTS.md) before contributing: it lists the project rules
and where each one is enforced. The product direction is in
[`docs/product/vision.md`](docs/product/vision.md) and the plan of record is
[`docs/roadmap.md`](docs/roadmap.md).

## Repository layout

```text
packages/core/        Shared domain rules (zero runtime dependencies)
  src/time/           UTC timestamps that keep the original time zone
  src/data/           Measurements that are either present or explicitly missing
  src/consent/        External data sources and the append-only consent log
  src/privacy/        Guard against data FlowWave must never collect
  src/sync/           Idempotent sync operations and the offline outbox
  src/scoring/        Energy estimate with per-factor explanations
  test/               Unit tests (Node's built-in test runner)
db/migrations/        PostgreSQL migrations (NNNN_name.up.sql / .down.sql)
db/tests/             SQL constraint tests, run inside a rolled-back transaction
docs/architecture/    Decision notes; write one before changing architecture
docs/privacy/         Data inventory: every collected field and why
docs/product/         Product vision: problem, limits, planned data, design principles
docs/roadmap.md       Phased plan of record
scripts/              Developer and CI scripts
```

The mobile app and the sync API are not built yet. Each will get a decision
note in `docs/architecture` before it is added.

## Requirements

- Node.js 22.12 or newer (see `.nvmrc`)
- PostgreSQL 13 or newer, only for migration checks (CI uses 16)

## Commands

```bash
npm ci                       # install the pinned dev dependencies
npm run typecheck            # strict TypeScript check
npm test                     # build and run unit tests
npm run check                # both of the above

# Apply migrations, run SQL tests, revert, and re-apply, on a disposable database:
DATABASE_URL=postgres://user:pass@localhost:5432/flowwave_test ./scripts/verify-migrations.sh
```

## Key behaviors

- **Timestamps** are stored as a UTC instant plus the IANA zone and offset at
  that moment. Timestamps without an offset are rejected.
- **Missing data** is a value with a reason (`user_skipped`, `no_consent`, ...).
  The estimate leaves missing inputs out and says which ones were missing.
- **Consent** is required, per source and scope, before reading any external
  source, and is invalidated when the consent policy version changes.
- **Sync** operations carry a client-generated ID. Repeating an operation
  returns the stored result; reusing an ID for a different change is rejected.
- **Recommendations** always include an explanation built from the inputs and a
  disclaimer that the estimate is not a medical assessment.
