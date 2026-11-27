# Roadmap

This is the single plan of record for FlowWave. Plans prepared elsewhere are
merged into this file rather than kept in parallel. Product context:
[`vision.md`](product/vision.md) and [`mvp-scope.md`](product/mvp-scope.md).
Architecture: [`system-overview.md`](architecture/system-overview.md).

Each phase that changes architecture starts with a decision note in
[`docs/architecture`](architecture/README.md), and each new data field gets a
row in [`docs/privacy/data-inventory.md`](privacy/data-inventory.md) before it
is collected.

| Phase | Goal | MVP | Status |
| --- | --- | --- | --- |
| 0 | Foundations | | Done ([#1](https://github.com/CoderPawel/flowwave/pull/1)) |
| 1 | Android app with manual logging, offline | Yes | Next; waits on confirming [0005](architecture/0005-android-first-native-kotlin.md) |
| 2 | Wearable data through Health Connect | Yes | Planned |
| 3 | Phone screen use | Yes | Planned |
| 4 | NestJS sync API and opt-in backup | Yes | Planned |
| 5 | Rhythm, load, and explained suggestions | Yes | Planned |
| 6 | Hyperfocus and expected-dip prompts, richer patterns | | Later |
| 7 | Windows agent | | Later |
| 8 | Next.js web panel | | Later |
| 9 | iOS app | | Later |
| 10 | Printable report for a doctor or therapist | | Optional |

## Phase 0: Foundations (done)

Shared core domain (`@flowwave/core`): zoned timestamps, explicit missing data,
consent, privacy guard, idempotent sync, and an explained energy estimate.
Initial PostgreSQL schema, decision notes 0001–0004, CI.

## Phase 1: Android app with manual logging, offline

- **Decisions:** [0005](architecture/0005-android-first-native-kotlin.md)
  (native Kotlin, proposed) and
  [0007](architecture/0007-android-offline-first-storage.md) (Room, SQLCipher,
  WorkManager).
- **Scope:** MVP features F1–F5: one-tap check-ins, meal / caffeine / exercise /
  rest logs, manual sleep, day timeline, energy estimate with explanation.
- **Also:** shared JSON test vectors in `packages/core/test/vectors/` used by
  both the TypeScript and Kotlin tests; Android CI job.
- **Data added:** life events (meal, caffeine, exercise, rest) and manual sleep
  sessions in core models, inventory, and schema.
- **Done when:** F1–F5 acceptance criteria in the MVP scope pass on the owner's
  phone, offline.

## Phase 2: Wearable data through Health Connect

- **Prerequisite for the owner:** move the Mi Band from Zepp Life to Mi Fitness
  and enable its Health Connect permissions.
- **Decision:** [0006](architecture/0006-health-connect-wearable-gateway.md).
- **Scope:** F6–F7: consent per data type; import sleep sessions, steps, heart
  rate, resting heart rate, and exercise sessions.
- **Data added:** replace the `health_connect` scope `sleep_duration` with the
  scopes in 0006, bump the consent policy version, add schema and inventory rows.
- **Done when:** F6–F7 acceptance criteria pass.

## Phase 3: Phone screen use

- **Scope:** F8: screen-on minutes and unlock counts per hour from
  `UsageStatsManager`, computed on the device
  ([data flow](architecture/data-flow.md#screen-use-aggregation)).
- **Never:** app names, window titles, URLs, file names, keystrokes.
- **Done when:** F8 acceptance criteria pass.

## Phase 4: NestJS sync API and opt-in backup

- **Decision:** [0008](architecture/0008-nestjs-sync-api.md); new decision
  notes for authentication and EU hosting before work starts.
- **Scope:** F9: account, idempotent sync, restore, export, account deletion.
- **Done when:** F9 acceptance criteria and the API acceptance criteria in 0008
  pass in CI against PostgreSQL.

## Phase 5: Rhythm, load, and explained suggestions

- **Decision note first:** statistical method, minimum data per pattern, how
  confidence and history length are shown.
- **Scope:** F10–F12: rhythm view, load view, day suggestions.
- **Done when:** F10–F12 acceptance criteria pass; the MVP exit criteria in
  [`mvp-scope.md`](product/mvp-scope.md#mvp-is-done-when) are met.

## Later phases

- **6. Prompts and patterns:** hyperfocus safety-net prompts, expected-dip
  prompts, relationships between sleep, meals, caffeine, movement, and screen
  use.
- **7. Windows agent:** active and idle minutes from the system idle timer;
  decision note on language, packaging, and pairing.
- **8. Next.js web panel:** read-only views first, using the sync API.
- **9. iOS app:** Apple Health; revisit Kotlin Multiplatform (see 0005).
- **10. Printable report (optional):** generated on the device, shared only by
  the user.

## Reconciliation log

| Date | Source | Result |
| --- | --- | --- |
| 2026-11-27 | Copilot prompt 1 (architecture documents) | Merged. Platforms (Android first, NestJS, PostgreSQL; Next.js, iOS, Windows later), Health Connect and `UsageStatsManager`, and caffeine and exercise events adopted. Changes: decision notes numbered 0005–0008 in the existing `docs/architecture/NNNN-title.md` convention instead of `adr/001–003`; offline-first builds on existing note 0004 instead of duplicating it; added note 0008 for NestJS because it is a new dependency; Zepp Life corrected as unsupported (no direct Health Connect link); mobile stack proposed as native Kotlin instead of the earlier React Native proposal; MVP phases reordered so screen use and sync come before patterns, and the Windows agent moves after the MVP. |
| 2026-11-27 | Rest of the owner's earlier schedule | Pending: remaining prompts to be compared and merged here |
