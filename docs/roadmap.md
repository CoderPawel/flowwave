# Roadmap

This is the single plan of record for FlowWave. Plans prepared elsewhere are
merged into this file rather than kept in parallel. The product context is in
[`docs/product/vision.md`](product/vision.md).

Each phase that changes architecture starts with a decision note in
[`docs/architecture`](architecture/README.md), and each new data field gets a
row in [`docs/privacy/data-inventory.md`](privacy/data-inventory.md) before it
is collected.

| Phase | Goal | Status |
| --- | --- | --- |
| 0 | Foundations | Done ([#1](https://github.com/CoderPawel/flowwave/pull/1)) |
| 1 | Mobile app with manual logging, offline | Next |
| 2 | Wearable data through Health Connect | Planned |
| 3 | Phone screen time and computer activity | Planned |
| 4 | Personal patterns and day plan | Planned |
| 5 | Printable report for a doctor or therapist | Optional |

## Phase 0: Foundations (done)

Shared core domain (`@flowwave/core`): zoned timestamps, explicit missing data,
consent, privacy guard, idempotent sync, and an explained energy estimate.
Initial PostgreSQL schema, decision notes 0001–0004, CI.

## Phase 1: Mobile app with manual logging, offline

- **Decision note first:** mobile stack and local storage. Proposed: React
  Native with Expo and on-device SQLite, reusing `@flowwave/core`.
- **Scope:** one-tap energy and focus check-ins (notification and home-screen
  widget), meal log (time and size), manual sleep log, break start and stop,
  a daily view, and the existing energy estimate with its explanation.
- **Data added:** meals and breaks (inventory rows and core models with tests).
- **Done when:** the app runs fully offline on Android, every entry is stored
  with a zoned timestamp, missing inputs are shown as missing, and each
  estimate shows its explanation and disclaimer.

## Phase 2: Wearable data through Health Connect

- **Prerequisite for the owner:** move the Mi Band from Zepp Life to Mi Fitness
  and enable its Health Connect permissions (see the vision document).
- **Decision note first:** Health Connect adapter, read scopes, import window,
  and deduplication of overlapping records.
- **Scope:** consent screen per data type; import sleep sessions, steps, and
  heart rate; show the source of each value.
- **Data added:** extend the `health_connect` scopes beyond `sleep_duration`
  (steps, heart rate) in the core registry, schema, and inventory.
- **Done when:** revoking consent stops imports immediately, re-importing the
  same records creates no duplicates, and metrics the band does not export are
  shown as missing.

## Phase 3: Phone screen time and computer activity

- **Decision notes first:** Android usage-statistics collector, and the
  Windows agent (language, packaging, how it pairs with the phone).
- **Scope:** total screen-on minutes per hour on Android, computed on the
  device; Windows agent reporting active and idle minutes from the system idle
  timer.
- **Never:** app names, window titles, URLs, file names, keystrokes. The privacy
  guard in the core rejects such fields.
- **Done when:** both collectors work offline, sync idempotently, and can be
  paused or turned off at any time.

## Phase 4: Personal patterns and day plan

- **Decision note first:** pattern method, minimum data per pattern, and how
  confidence is shown.
- **Scope:** personal energy and focus curve by time of day; observed
  relationships with sleep, meals, movement, breaks, and screen time; a
  suggested day plan; hyperfocus and expected-dip prompts.
- **Done when:** every pattern and suggestion lists its inputs, missing inputs,
  and the amount of history behind it, and the wording follows the vision
  document.

## Phase 5: Printable report (optional)

A user-initiated summary of the person's own data and patterns to bring to an
appointment. Generated on the device and shared only by the user.

## Reconciliation log

| Date | Source | Result |
| --- | --- | --- |
| 2026-11-27 | Owner's earlier schedule from another assistant | Pending: to be compared and merged into this file |
