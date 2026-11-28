# 0010. Prisma for the schema and data access

- Status: Accepted
- Date: 2026-11-27
- Supersedes: the database-access part of [0008](0008-nestjs-sync-api.md) (`pg` driver, plain SQL migrations in `db/migrations`, no ORM)

## Context

Decision note 0008 chose the `pg` driver and plain SQL migrations. The owner's
plan (Copilot prompts 2 and 3) chooses Prisma for the schema, migrations, and
data access in the NestJS API. The existing schema relies on PostgreSQL
features Prisma's schema language does not express: CHECK constraints
(present-or-missing values, ranges), an append-only trigger on consent, and
array containment checks.

## Decision

- `apps/api/prisma/schema.prisma` is the source of truth for tables, columns,
  relations, indexes, and unique constraints. Migrations live in
  `apps/api/prisma/migrations` and are created with `prisma migrate`.
- Constraints Prisma cannot express are added as hand-written SQL inside the
  generated migration files, in the same migration as the table. They are
  never dropped silently: SQL constraint tests in `db/tests` keep running
  against the Prisma-migrated database in CI.
- The existing `db/migrations/0001_initial_schema` is ported into the first
  Prisma migration in the data-model phase (prompt 3), with every constraint
  and test preserved, and then removed from `db/migrations`. Until then both
  exist and CI keeps verifying the SQL version. Done in step 3
  ([0012](0012-data-model.md)).
- Application code queries through Prisma Client; raw SQL is allowed only
  through Prisma's parameterized `$queryRaw` tagged template.

## Dependencies

| Dependency | Why it is required |
| --- | --- |
| `prisma` (dev) | Schema language, migration generation and application, client generation. |
| `@prisma/client` | Typed database access for the API. |

## Consequences

- Typed queries and a common migration workflow for API developers.
- Constraint-heavy rules live partly outside `schema.prisma`; reviewers must
  read the migration SQL too. The SQL tests make regressions visible.

## Acceptance criteria

- `prisma migrate deploy` on an empty database followed by `db/tests/*.sql`
  passes in CI.
- `prisma migrate diff` between the schema and the migrations reports no drift.
