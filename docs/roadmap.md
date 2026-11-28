# Roadmap

This is the single plan of record for FlowWave. Plans prepared elsewhere are
merged into this file rather than kept in parallel. Product context:
[`vision.md`](product/vision.md) and [`mvp-scope.md`](product/mvp-scope.md).
Architecture: [`system-overview.md`](architecture/system-overview.md).

Step numbers match the owner's Copilot prompts, so "step 6" is "prompt 6".
Each step that changes architecture starts with a decision note in
[`docs/architecture`](architecture/README.md), and each new data field gets a
row in [`docs/privacy/data-inventory.md`](privacy/data-inventory.md) before it
is collected.

| Step | Goal | MVP | Status |
| --- | --- | --- | --- |
| 0 | Foundations: shared core, first schema, CI | Yes | Done ([#1](https://github.com/CoderPawel/flowwave/pull/1)) |
| 1 | Architecture documents | Yes | Done ([#2](https://github.com/CoderPawel/flowwave/pull/2)) |
| 2 | Monorepo: API, web, mobile, contracts, analytics engine, Docker, CI | Yes | Done ([#3](https://github.com/CoderPawel/flowwave/pull/3), [0011](architecture/0011-monorepo-layout-and-tooling.md)) |
| 3 | Data model in Prisma | Yes | Done in a pull request ([0012](architecture/0012-data-model.md), [data dictionary](data/data-dictionary.md)) |
| 4 | Authentication, consent, export, deletion | Yes | Planned |
| 5 | Flutter app foundation | Yes | Planned |
| 6 | Self check-in | Yes | Planned |
| 7 | Lifestyle events and focus sessions | Yes | Planned |
| 8 | Health Connect | Yes | Planned |
| 9 | Android device-usage aggregation | Yes | Planned |
| 10 | Offline-first synchronization | Yes | Planned |
| 11 | Rhythm engine v1 | Yes | Planned; needs decision A |
| 12 | Energy Score and Intensity Debt | Yes | Planned; needs decision A |
| 13 | Today dashboard | Yes | Planned |
| 14 | Recommendation engine | Yes | Planned |
| 17 | Security and privacy review | Yes | Planned; moved before the pilot |
| 16 | Closed Android pilot | Pilot | Planned; needs decision B |
| 15 | Web panel | After pilot start | Planned |

## Decisions the owner still needs to make

- **A. Where the rhythm engine runs (steps 11–14).** The plan writes the engine
  in TypeScript (`packages/analytics-engine`) and stores scores on the server,
  so insights require sync to be on; the phone shows the last results offline.
  The alternative is to also port the engine to Dart so insights work with no
  account, at the cost of two implementations. Recommended: server-side engine,
  with explicit consent for server processing, EU hosting, and capture that
  still works fully offline.
- **B. Crash reporting and telemetry provider (step 16).** The security
  boundaries forbid third-party analytics SDKs in the MVP. Recommended: own
  telemetry endpoint in the API (counts only, no health values) and an
  EU-hosted crash reporter with consent, chosen in a decision note.

## Step details and changes from the owner's plan

Each step is implemented as the prompt describes, except for the listed
changes, which keep it consistent with the project rules and earlier decisions.

**Step 2. Monorepo.** Adopted: `apps/api` (NestJS, Prisma, Swagger,
class-validator, config validation, structured logging, health endpoint),
`apps/web` (Next.js, Tailwind), `apps/mobile` (Flutter),
`packages/contracts`, `packages/analytics-engine`, `infrastructure/docker`,
environment templates, CI for lint, test, and build. Changes: keeps the
existing npm workspaces and `packages/core`; adds ESLint (needed for the lint
requirement); keeps `db/migrations` until step 3 ports it to Prisma
([0010](architecture/0010-prisma-schema-and-data-access.md)); Flutter replaces
the proposed Kotlin app ([0009](architecture/0009-flutter-mobile-app.md)).

**Step 3. Data model.** Adopted: all 18 entities and requirements, a
migration, a synthetic seed, an ER diagram, repository tests for idempotent
imports, and a data dictionary ([0012](architecture/0012-data-model.md)).
Changes: the existing constraints (present-or-missing values, ranges,
append-only consent, cascade deletion) are ported, not dropped, and
`db/migrations` is removed; `AppliedSyncOperation` is kept (rule 16); heart
rate is stored as 5-minute aggregates and steps as hourly totals, not raw
samples ([data flow](architecture/data-flow.md)); device usage is stored as
30-minute category buckets without package names, as step 9 plans; Prisma has
no down migrations, so each migration carries a hand-written `down.sql` checked
in CI; constraints Prisma cannot express (ranges, present-or-missing, explanation
shape, per-user composite foreign keys) are SQL in the migration. Tables for
steps 4–14 exist but stay empty until their step; the
[data inventory](privacy/data-inventory.md) marks them "schema only".

**Step 4. Authentication and privacy.** Adopted as written. Changes: a decision
note on authentication first (promised in 0008); the four consent types
(health data, device usage, notifications, analytics) extend the core consent
model, which currently covers only external sources.

**Step 5. Flutter foundation.** Adopted as written.

**Step 6. Check-in.** Adopted: energy, focus, and overload on a 1–10 scale, and
the optional values. Changes: the existing energy estimate uses a 1–5 scale; it
stays available as calculation version 1 and step 12 adds the new version
(existing functionality is not deleted). The free-text note is never logged,
never sent to analytics or telemetry, and is included in export and deletion.

**Step 7. Lifestyle events.** Adopted as written. Addition: manual sleep entry
from the MVP scope stays, because the pilot includes users without a wearable.

**Step 8. Health Connect.** Adopted, except: Zepp Life cannot be supported
because it does not write to Health Connect; testing steps use Mi Fitness
([0006](architecture/0006-health-connect-wearable-gateway.md)). Active and
total calories, distance, HRV, and oxygen saturation are deferred until a
feature uses them, because no step 11–14 calculation needs them (rule 4).

**Step 9. Device usage.** Adopted: consent, 30-minute buckets, category
aggregates, app switches, unlock count, screen-active time, education screen,
WorkManager. Changes: package identifiers are mapped to categories in memory
and never stored, even on the phone; categories come from a local mapping table,
so FlowWave does not need the restricted permission to list installed apps;
unlocks are counted from the permitted keyguard events. The data-flow document
changes from hourly totals to 30-minute category buckets.

**Step 10. Synchronization.** Adopted as written; builds on
[0004](architecture/0004-offline-first-idempotent-sync.md).

**Step 11. Rhythm engine v1.** Adopted as written. Depends on decision A.
Labels READY, FLOW, RECOVERY, and OVERDRIVE follow the wording rules in the
vision document.

**Step 12. Energy Score and Intensity Debt.** Adopted as written. The current
energy estimate becomes version 1 of the Energy Score configuration.

**Step 13. Today dashboard.** Adopted as written.

**Step 14. Recommendations.** Adopted as written.

**Step 17. Security review (moved before step 16).** Adopted as written. Moved
because pilot testers' health data should only be collected after the review.

**Step 16. Pilot.** Adopted. Depends on decision B. The privacy notice and
informed consent are drafts that need review by a lawyer before use.

**Step 15. Web panel.** Adopted as written; it can start once the API from
steps 3–12 exists and is not required for the Android pilot.

## Reconciliation log

| Date | Source | Result |
| --- | --- | --- |
| 2026-11-27 | Copilot prompt 1 (architecture documents) | Merged. Platforms (Android first, NestJS, PostgreSQL; Next.js, iOS, Windows later), Health Connect and `UsageStatsManager`, and caffeine and exercise events adopted. Changes: decision notes numbered 0005–0008 in the existing `docs/architecture/NNNN-title.md` convention instead of `adr/001–003`; offline-first builds on existing note 0004 instead of duplicating it; added note 0008 for NestJS because it is a new dependency; Zepp Life corrected as unsupported (no direct Health Connect link). |
| 2026-11-27 | Copilot prompts 2–17 | Merged into steps 2–17 above. Flutter and Prisma adopted (notes 0009 and 0010, superseding 0005 and parts of 0007 and 0008). Changes listed per step; security review moved before the pilot; decisions A and B open. |
| 2026-11-27 | Copilot prompt 3 (data model), pasted in full | Implemented as step 3. Changes from the prompt: existing constraints and `AppliedSyncOperation` kept; aggregates instead of raw heart-rate samples; usage buckets without package names; hand-written `down.sql` for reversibility; calories, distance, HRV and oxygen saturation left out (rule 4). Prompt saved in [`docs/prompts`](prompts/prompt-03-data-model.md). |
