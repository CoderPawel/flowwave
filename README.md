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
  prisma/             Prisma schema and migrations (each with a hand-written down.sql)
  src/importedRecords/  Idempotent imports of health samples, sleep, and usage buckets
  src/seed/           Clearly marked synthetic records for development
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
db/tests/             SQL constraint tests, run inside a rolled-back transaction
docs/architecture/    Decision notes; write one before changing architecture
docs/data/            Data dictionary and ER diagram
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
npm run generate             # build packages/core and generate the Prisma client
npm run build                # build every workspace
npm run contracts:generate   # regenerate packages/contracts from the API
npm run contracts:check      # fail if the committed contract is out of date

npm run dev:api              # API on http://localhost:3000 (Swagger UI at /docs)
npm run dev:web              # web panel on http://localhost:3001
```

API endpoints are versioned under `/v1` and listed in Swagger UI and
[`packages/contracts/openapi.json`](packages/contracts/openapi.json):

- `GET /v1/health`, `GET /v1/health/ready`: liveness and database readiness
  (`503` when the database is down); the only routes without a token.
- `/v1/auth/*`: register, sign in, refresh, sign out (one device or all), list
  and revoke sessions ([0013](docs/architecture/0013-authentication-and-sessions.md)).
- `/v1/consents`: consent status, history, and decisions for health data,
  device usage, notifications, and analytics.
- `/v1/account`: the account, deletion (password required), and data export
  jobs ([0014](docs/architecture/0014-consent-types-export-and-deletion.md)).

Try it locally (registration is on by default outside production):

```bash
curl -s localhost:3000/v1/auth/register -H 'content-type: application/json' \
  -d '{"email":"me@example.org","password":"a long password","homeTimeZone":"Europe/Budapest","device":{"platform":"web"}}'
curl -s localhost:3000/v1/account -H "authorization: Bearer <accessToken from the response>"
```

Authentication settings in `apps/api/.env` (see `.env.example`):
`ACCESS_TOKEN_TTL_SECONDS` (default 900), `REFRESH_TOKEN_TTL_DAYS` (30),
`AUTH_REGISTRATION_ENABLED` (off in production unless set), `TRUST_PROXY_HOPS`
(reverse proxies in front of the API, for client IPs in rate limits),
`RATE_LIMIT_ENABLED` and `BACKGROUND_JOBS_ENABLED` (both on; tests turn them
off).

Tests that need a real database and the migration check use a disposable
database (Docker Compose creates `flowwave_test` on first start):

```bash
export FLOWWAVE_TEST_DATABASE_URL=postgresql://flowwave:<password>@localhost:5432/flowwave_test
npm test -w @flowwave/api

# Apply migrations, check drift against schema.prisma, run SQL tests, revert, and re-apply:
DATABASE_URL=$FLOWWAVE_TEST_DATABASE_URL npm run db:verify
```

Development database (uses `DATABASE_URL` from `apps/api/.env`):

```bash
npm run db:migrate           # apply migrations (prisma migrate deploy)
npm run db:seed              # add synthetic records (users.is_synthetic = true); safe to repeat
```

The seed refuses to run with `NODE_ENV=production`. Every seeded record is
marked synthetic and uses the `synthetic` data source, so it can never be
mistaken for real health data. Schema changes: edit `schema.prisma`, run
`npm exec -w @flowwave/api -- prisma migrate dev --create-only --name <name>`,
add the constraints Prisma cannot express to the generated `migration.sql`,
write `down.sql`, and document new columns in
[`docs/data/data-dictionary.md`](docs/data/data-dictionary.md) and
[`docs/privacy/data-inventory.md`](docs/privacy/data-inventory.md).

Mobile app:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

# Point a debug build at a local API (Android emulator):
flutter run --dart-define=FLOWWAVE_API_BASE_URL=http://10.0.2.2:3000/
```

## Key behaviors

- **Timestamps** are stored as a UTC instant plus the IANA zone and offset at
  that moment. Timestamps without an offset are rejected.
- **Missing data** is a value with a reason (`user_skipped`, `no_consent`, ...).
  The estimate leaves missing inputs out and says which ones were missing.
- **Consent** is separate for health data (per source and scope), device
  usage, notifications, and analytics. It is required before collecting that
  data, is invalidated when its consent text version changes, and can be
  withdrawn at any time, optionally deleting the data collected under it.
- **Accounts** use email and password (Argon2id) with short-lived access tokens
  and single-use refresh tokens; reusing a refresh token signs that device out.
  Account deletion removes all server data at once.
- **Sync** operations carry a client-generated ID. Repeating an operation
  returns the stored result; reusing an ID for a different change is rejected.
- **Recommendations** always include an explanation built from the inputs and a
  disclaimer that the estimate is not a medical assessment.
