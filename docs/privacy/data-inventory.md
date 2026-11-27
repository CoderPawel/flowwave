# Data inventory

Every piece of data FlowWave stores must be listed here with the feature that
needs it. A field without a row here must not exist in code or schema
(see [0003](../architecture/0003-privacy-and-consent.md)).

## Never collected

FlowWave never collects, stores, or transmits:

- window titles or active application names,
- URLs or browsing history,
- document contents,
- messages (chat, email, SMS),
- file names or paths,
- keystrokes or typed text.

`assertNoForbiddenFields` in `@flowwave/core` rejects sync payloads that contain
keys for these categories.

## Collected

| Table / field | Sensitivity | Source | Feature | Why it is needed |
| --- | --- | --- | --- | --- |
| `users.id` | Identifier | Generated | Account | Links a user's records together. |
| `users.home_time_zone` | Low | User / device | Local-day grouping | Default zone for showing days and scheduling. |
| `users.sleep_goal_minutes` | Health (user goal) | User | Energy estimate | Sleep is compared with the user's own goal, not a clinical norm. |
| `consent_decisions.*` | Low | User | Consent | Proof of what the user allowed, and when; required to read external sources. |
| `check_ins.recorded_at_*` | Behavior | Device | Energy estimate | When the check-in happened, in UTC plus the original zone. |
| `check_ins.self_reported_energy` | Health (self-report) | Manual check-in | Energy estimate | Main input of the estimate. |
| `check_ins.sleep_duration_minutes` | Health | Manual check-in; Apple Health or Health Connect only with consent | Energy estimate | Secondary input of the estimate. |
| `check_ins.sleep_duration_source` | Low | Derived | Energy estimate | Shows where the sleep value came from in explanations. |
| `check_ins.*_missing_reason` | Low | Derived | Energy estimate | Records why an input is absent instead of inventing it. |
| `check_ins.version`, `*_at_utc` timestamps | Low | Generated | Sync | Optimistic concurrency and tombstones for offline sync. |
| `applied_sync_operations.*` | Low (contains result, not payload) | Generated | Sync | Makes retried operations idempotent. |

## Declared external sources (not yet integrated)

| Source | Scopes FlowWave may request | Status |
| --- | --- | --- |
| Apple Health | `sleep_duration` | Declared only; no adapter exists, nothing is collected. |
| Health Connect | `sleep_duration` | Declared only; no adapter exists, nothing is collected. |

## Deletion

Deleting a user row cascades to all of their check-ins, consent decisions, and
sync records (covered by `db/tests/0001_initial_schema.test.sql`).
