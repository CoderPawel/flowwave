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
apps/api/             NestJS API: config validation, structured logs, health, Swagger
  prisma/             Prisma schema (models arrive in roadmap step 3)
apps/web/             Next.js web panel with Tailwind (scaffold until step 15)
apps/mobile/          Flutter Android app, offline-first (outside npm workspaces)
packages/core/        Shared domain rules (zero runtime dependencies)
  src/time/           UTC timestamps that keep the original time zone
  src/data/           Measurements that are either present or explicitly missing
  src/consent/        External data sources and the append-only consent log
  src/privacy/        Guard against data FlowWave must never collect
  src/sync/           Idempotent sync operations and the offline outbox
  src/scoring/        Energy estimate with per-factor explanations
packages/analytics-engine/  Rhythm and score calculations with calculation metadata
packages/contracts/   OpenAPI document generated from the API, plus TypeScript types
infrastructure/docker/      Docker Compose for local PostgreSQL
db/migrations/        PostgreSQL migrations (NNNN_name.up.sql / .down.sql)
db/tests/             SQL constraint tests, run inside a rolled-back transaction
docs/architecture/    Decision notes; write one before changing architecture
docs/privacy/         Data inventory: every collected field and why
docs/product/         Product vision and MVP scope
docs/roadmap.md       Phased plan of record
scripts/              Developer and CI scripts
```

## Requirements

- Node.js 22.18 or newer (see `.nvmrc`)
- Docker with Compose, or a local PostgreSQL 16
- Flutter 3.50 (stable) with the Android SDK and JDK 17, only for `apps/mobile`

## Setup

```bash
git clone https://github.com/CoderPawel/flowwave.git
cd flowwave
npm ci

# Local PostgreSQL (binds to 127.0.0.1 only). Set your own password in the copied files.
cp infrastructure/docker/.env.example infrastructure/docker/.env
docker compose -f infrastructure/docker/docker-compose.yml --env-file infrastructure/docker/.env up -d

# API configuration; the password must match infrastructure/docker/.env
cp apps/api/.env.example apps/api/.env
cp apps/web/.env.example apps/web/.env.local

# Optional: turn off Next.js anonymous telemetry on this machine
npx --workspace @flowwave/web next telemetry disable
```

On Windows PowerShell use `Copy-Item` instead of `cp`; every npm script works
the same way on Windows, macOS, and Linux.

## Commands

```bash
npm run lint                 # ESLint for TypeScript packages, API, and web panel
npm run typecheck            # strict TypeScript check of every workspace
npm test                     # build and run all TypeScript unit tests
npm run check                # lint + typecheck + test
npm run build                # build every workspace (generates the Prisma client)
npm run contracts:generate   # regenerate packages/contracts from the API
npm run contracts:check      # fail if the committed contract is out of date

npm run dev:api              # API on http://localhost:3000 (Swagger UI at /docs)
npm run dev:web              # web panel on http://localhost:3001
```

API endpoints are versioned under `/v1`: `GET /v1/health` (liveness) and
`GET /v1/health/ready` (database readiness, `503` when the database is down).

Tests that need a real database and the migration check use a disposable
database (Docker Compose creates `flowwave_test` on first start):

```bash
export FLOWWAVE_TEST_DATABASE_URL=postgresql://flowwave:<password>@localhost:5432/flowwave_test
npm test -w @flowwave/api

# Apply migrations, run SQL tests, revert, and re-apply:
DATABASE_URL=$FLOWWAVE_TEST_DATABASE_URL ./scripts/verify-migrations.sh
```

Mobile app:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
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
