# 0006. Health Connect as the only wearable gateway

- Status: Accepted
- Date: 2026-11-27

## Context

The owner uses an older Xiaomi Mi Band. FlowWave needs sleep, steps, heart
rate, and exercise sessions from it. Xiaomi publishes no public health API, and
its Bluetooth protocol is proprietary and differs between band models.

Findings as of 2026-11-27:

- **Mi Fitness** (Xiaomi Wear), Xiaomi's current app, writes to Health Connect.
- **Zepp Life**, used by older Mi Band models, has no direct Health Connect
  integration. Its Android route was Zepp Life → Google Fit → Health Connect,
  and Google supports the Google Fit APIs only until the end of 2026. Some
  older bands (for example the Mi Band 6) can be moved to Mi Fitness.
- Health Connect is built into Android 14+ and available as an app on Android
  9–13. By default an app can read data from up to 30 days before its first
  permission grant; older data needs `READ_HEALTH_DATA_HISTORY`. Background
  reads need `READ_HEALTH_DATA_IN_BACKGROUND`. Changes tokens expire after 30
  days without use. Background reads have stricter rate limits.

## Decision

- FlowWave reads wearable data only from Health Connect. It never connects to
  the band over Bluetooth and never uses Xiaomi's cloud.
- The supported path for Mi Band users is Mi Fitness → Health Connect.
  Zepp Life is treated as unsupported unless it writes to Health Connect
  directly in the future. Onboarding explains how to move a band to Mi Fitness.
- Record types and Health Connect permissions in the MVP:

  | FlowWave scope | Health Connect record | Permission |
  | --- | --- | --- |
  | `sleep_sessions` | `SleepSessionRecord` (with stages if present) | `READ_SLEEP` |
  | `steps` | `StepsRecord` (read through the aggregate API) | `READ_STEPS` |
  | `heart_rate` | `HeartRateRecord` | `READ_HEART_RATE` |
  | `resting_heart_rate` | `RestingHeartRateRecord` | `READ_RESTING_HEART_RATE` |
  | `exercise_sessions` | `ExerciseSessionRecord` | `READ_EXERCISE` |

- `READ_HEALTH_DATA_IN_BACKGROUND` is requested for hourly imports; without it,
  imports run when the app is opened. `READ_HEALTH_DATA_HISTORY` is requested
  only if the user chooses to import older history.
- Each scope has its own consent decision in the core consent log, mirroring
  the Health Connect permission. If a permission is revoked in system settings,
  the next import records a revocation and stops reading that type.
- Import uses one changes token per record type; on token expiry it re-reads
  from the last imported time (at most 30 days) and deduplicates by Health
  Connect record ID ([data flow](data-flow.md#health-connect-import)).
- FlowWave does not write to Health Connect in the MVP.
- The `health_connect` scopes in `packages/core/src/consent/dataSources.ts`
  (currently `sleep_duration`) are replaced by the scopes above in phase 2,
  together with a consent policy version bump, schema migration, and data
  inventory rows.

## Consequences

- Works with any band or watch whose app writes to Health Connect (Mi Fitness,
  Zepp for Amazfit, Samsung Health, Fitbit, Garmin Connect), with no
  vendor-specific code.
- Data quality depends on the vendor app: some bands measure HRV or stress but
  do not export them. Anything not in Health Connect is treated as missing.
- Owners of bands that cannot use Mi Fitness get no wearable data; manual sleep
  logging still works.
- Google Play requires a health permissions declaration and a permission
  rationale screen before release.

## Acceptance criteria

- Reading a record type without its permission or consent is impossible in code
  (adapter checks both) and is covered by tests.
- Importing the same Health Connect data twice produces no duplicates.
- Expired changes tokens are handled without data loss inside the 30-day window.
- Steps are not double counted when both phone and band write steps.
