# 0012. Data model

- Status: Accepted
- Date: 2026-11-27
- Implements: roadmap step 3 ([prompt 3](../prompts/prompt-03-data-model.md)); completes the port planned in [0010](0010-prisma-schema-and-data-access.md)

## Context

Prompt 3 asks for 18 entities in Prisma with UUID keys, UTC timestamps plus the
original time zone, soft deletion, idempotency keys and Health Connect record
IDs for imports, uniqueness that prevents duplicate synchronization, explicit
units, missing values that are never zero, provider metadata, and per-user
isolation. The schema from step 0 (`db/migrations/0001`) already enforced time,
missing-data, consent and deletion rules with CHECK constraints and triggers.

## Decision

**Entities.** All 18 entities from the prompt, plus `AppliedSyncOperation`,
which existed before and is kept (project rule 16). Model names follow the
prompt; existing tables keep their names (`Consent` is `consent_decisions`,
`SelfCheckIn` is `check_ins`). The [data dictionary](../data/data-dictionary.md)
describes every column and the [ER diagram](../data/er-diagram.md) the relations.

**Port.** The first Prisma migration (`20261127220000_initial_schema`)
recreates the four existing tables with every constraint and replaces
`db/migrations`. The step 0 SQL tests run unchanged against it, except one
expected error code: missing reasons are now a PostgreSQL enum, so an unknown
reason fails as `22P02` instead of `23514`.

**Conventions** (enforced by CHECK constraints in the migration SQL, tested in
`db/tests`):

- Event times: `<name>_at_utc` (`timestamptz`) + `<name>_time_zone` (IANA,
  validated by `flowwave_is_valid_time_zone`) + `<name>_utc_offset_minutes`.
- Optional measured values have a `*_missing_reason` partner; exactly one of
  the two is set. Missing data is never stored as zero (rules 11 and 12).
- Units are part of the column name (`_minutes`, `_seconds`, `_count`,
  `_ratio`) or an explicit `unit` column checked against the metric.
- Enum values are lowercase and match `@flowwave/core` and the API.
- `created_at_utc` and `updated_at_utc` on every mutable table;
  `updated_at_utc` is set by a trigger, so raw SQL cannot forget it.
  Append-only tables (`consent_decisions`, `audit_events`) have no
  `updated_at_utc`, and a trigger rejects updates.

**Soft deletion** (`deleted_at_utc`) where a deletion must synchronize to other
devices or be traceable: user-entered events, imported health records (a
deletion at the source becomes a tombstone), devices (signed out) and data
sources (disconnected). Not on derived data (`daily_scores`, `rhythm_buckets`,
`recommendations`), which is recomputed, nor on `users`: deleting an account
hard-deletes everything by cascade (rule 3). Purging old tombstones is part of
step 4 (deletion and export).

**Imports.** Imported tables (`health_samples`, `sleep_sessions`,
`activity_sessions`, `device_usage_buckets`) have:

- `idempotency_key`, unique per user;
- `source_record_id` (Health Connect record ID), unique per user and data
  source; NULL for values computed by the aggregate API;
- `device_usage_buckets` is also unique per device and bucket start;
- `source_updated_at_utc`, the modification time at the source.

Repositories in `apps/api/src/importedRecords` insert with
`ON CONFLICT DO NOTHING`, then compare: identical content is `unchanged`, a
newer source version is applied (`updated`), an older one is ignored
(`stale`), and different content with the same source version is an
`IdempotencyConflictError`. Updates are conditional on the stored version
being older, so concurrent imports cannot overwrite newer data.

**User isolation.** Every user-owned row has `user_id` with `ON DELETE
CASCADE`. Rows that point at another user-owned row (data source, device) use
a composite foreign key `(id, user_id)`, so the database rejects a row of one
user that references another user's source or device. Repositories always
take `user_id` and filter by it. Row-level security in PostgreSQL is
considered in step 4, together with authentication.

**Audit events** keep no health values. When a user is deleted, `user_id`
becomes NULL (the only update the append-only trigger allows), so the fact
that an account was deleted stays provable without keeping personal data.

**Device usage** is stored as 30-minute buckets with totals and seven
category columns. There is no column for package names, app names, window
titles, URLs, file names, messages or keystrokes; a SQL test fails if a column
with such a name appears (rule 5). `health_data_sources.provider_package` is
the health app that wrote data to Health Connect (for example Mi Fitness),
needed to explain where a value came from (rule 10); it is never used for
apps whose usage is measured.

**Calculated results** (`daily_scores`, `rhythm_buckets`, `recommendations`)
carry a semantic `calculation_version` and an `explanation` that a CHECK
requires to contain a `factors` array and a non-empty `disclaimer` (rules 2
and 10). `insufficient_data` results have no value instead of a zero.
Recommendations store a template key and parameters, never generated text.

**Reversibility.** Prisma has no down migrations, so each migration folder
holds a hand-written `down.sql`. `scripts/verify-migrations.sh` applies the
migrations, checks for drift against `schema.prisma`, runs the SQL tests,
reverts with `down.sql`, verifies nothing is left, and applies again.

## Deliberate limits

- Fields come from the roadmap steps that will use them. A step that needs
  more (for example step 6's 1–10 check-in scales, step 4's consent types)
  adds them in its own migration with data inventory rows.
- Calories, distance, HRV, oxygen saturation, GPS routes, food descriptions
  and product names have no columns (rule 4; roadmap step 8 deferral).
- Heart rate is stored as 5-minute aggregates and steps as hourly totals;
  CHECK constraints fix these windows.
- The usage categories may change in step 9; that needs a migration and a data
  inventory update.

## Consequences

- A broken client cannot store invented zeros, naive times, cross-user
  references or calculated results without an explanation; the database
  refuses them.
- Reviewers must read the migration SQL as well as `schema.prisma`.
- Each new migration needs a `down.sql`; CI fails without it.

## Acceptance criteria

- `scripts/verify-migrations.sh` passes in CI: deploy, no drift, SQL tests,
  revert, redeploy.
- Repository tests show repeated and concurrent imports store one row, newer
  versions update, older ones are ignored, and users cannot reach each other's
  sources.
- Every column appears in the data dictionary and the data inventory (checked
  by `apps/api/test/dataDictionary.test.ts`).
