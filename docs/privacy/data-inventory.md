# Data inventory

Every piece of data FlowWave stores must be listed here with the feature that
needs it. A field without a row here must not exist in code or schema
(see [0003](../architecture/0003-privacy-and-consent.md)).
`apps/api/test/dataDictionary.test.ts` fails if a database column is missing
from this file or from the [data dictionary](../data/data-dictionary.md),
which describes types and units.

## Never collected

FlowWave never collects, stores, or transmits:

- window titles or active application names,
- URLs or browsing history,
- document contents,
- messages (chat, email, SMS) or notification contents,
- file names or paths,
- keystrokes, typed text or clipboard contents,
- screenshots or accessibility service data,
- package or app names of the apps whose usage is measured (only category
  totals per 30 minutes leave the phone),
- device hardware identifiers (IMEI, serial number, advertising ID),
- location or GPS routes.

`assertNoForbiddenFields` in `@flowwave/core` rejects payloads that contain
keys for these categories, and `db/tests/02_data_model.test.sql` fails if a
database column with such a name appears.

## Status

- **Collected**: written by implemented code.
- **Schema only (step N)**: the column exists so the data model is complete
  ([0012](../architecture/0012-data-model.md)), but nothing writes it until
  roadmap step N is implemented. Only the synthetic seed
  (`users.is_synthetic = true`) and tests write these tables before then.

## Bookkeeping columns

Present on most tables and listed again in each table below: `id` (UUID),
`user_id` (owner), `created_at_utc`, `updated_at_utc`, `deleted_at_utc`
(tombstone for sync), `version` (optimistic concurrency). Sensitivity: low;
source: generated; feature: storage and offline sync.

## Tables

### `users`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id` | Identifier | Generated | Account | Collected | Links a user's records together. |
| `home_time_zone` | Low | User / device | Local-day grouping | Collected | Default zone for showing days and scheduling. |
| `sleep_goal_minutes` | Health (user goal) | User | Energy estimate | Collected | Sleep is compared with the user's own goal, not a clinical norm. |
| `is_synthetic` | Low | Seed script | Testing | Collected | Keeps synthetic records out of pilot analysis. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Collected | Bookkeeping. |

### `user_credentials`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `user_id`, `email` | Personal (contact) | User | Sign-in | Collected | Sign-in name. Not written to logs or audit events; no email is ever sent yet. |
| `password_hash` | Secret | Derived (Argon2id) | Sign-in | Collected | Checks the password without storing it. Never exported, logged, or returned. |
| `password_updated_at_utc` | Low | Server | Sign-in | Collected | When the password was set. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Collected | Bookkeeping. |

### `auth_sessions`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `device_id` | Low | Server | Device sessions | Collected | One signed-in device that the user can sign out. |
| `expires_at_utc`, `last_refreshed_at_utc` | Behavior | Server | Device sessions | Collected | Ends idle sessions; shows when a device was last active. |
| `revoked_at_utc`, `revoked_reason` | Low | Server | Device sessions, security | Collected | Signed-out sessions stay unusable; reuse detection is visible. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Collected | Bookkeeping. Deleted 30 days after the session ended. |

### `auth_tokens`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `session_id` | Low | Server | Sign-in | Collected | Links a token pair to its session. |
| `access_token_hash`, `refresh_token_hash` | Secret (hash) | Derived (SHA-256) | Sign-in | Collected | Recognizes tokens without storing them. Never exported or logged. |
| `access_expires_at_utc`, `refresh_expires_at_utc`, `rotated_at_utc` | Low | Server | Sign-in, reuse detection | Collected | Short-lived access; single-use refresh tokens. |
| `created_at_utc` | Low | Generated | Storage | Collected | Bookkeeping; deleted with the session. |

### `devices`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `platform` | Low | App | Device sessions, sync | Collected | Which installation synchronizes and can be signed out. Created by sign-in. |
| `app_version` | Low | App | Sync | Collected | Detects clients that need a newer protocol. |
| `last_seen_at_utc` | Behavior | Server | Device sessions | Collected | Set at sign-in and token refresh; shows active devices so the user can revoke one. |
| `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Storage | Collected | Bookkeeping; sign-out is a tombstone. |

### `consent_decisions`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `consent_type`, `source_id`, `state`, `scopes`, `policy_version` | Low | User | Consent | Collected | Proof of what the user allowed, per consent type; required before collecting health data or device usage. |
| `decided_at_utc`, `decided_time_zone`, `decided_utc_offset_minutes` | Low | Device | Consent | Collected | When the decision was made, in UTC plus the original zone. |
| `created_at_utc` | Low | Generated | Storage | Collected | Bookkeeping. |

### `health_data_sources`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `kind`, `source_key` | Low | App | Health import | Schema only (steps 7, 8) | Groups imported records by origin; idempotent reconnection. |
| `provider_package`, `provider_name` | Low (health app only) | Health Connect data origin | Explanations | Schema only (step 8) | Explanations say which health app a value came from (rule 10). |
| `recording_device_type`, `recording_device_manufacturer`, `recording_device_model` | Low | Health Connect metadata | Explanations | Schema only (step 8) | Distinguishes a band from a phone, which changes how reliable steps and heart rate are. |
| `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Storage | Schema only (steps 7, 8) | Bookkeeping; disconnecting is a tombstone. |

### `health_samples`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `data_source_id`, `metric`, `unit` | Health | Health Connect, with consent | Rhythm engine, scores | Schema only (step 8) | Identifies the aggregate and its unit. |
| `start_at_utc`, `start_time_zone`, `start_utc_offset_minutes`, `end_at_utc`, `end_time_zone`, `end_utc_offset_minutes` | Health | Health Connect | Rhythm engine | Schema only (step 8) | Interval of the aggregate (rule 9). |
| `value`, `min_value`, `max_value`, `sample_count` | Health | Health Connect | Rhythm engine, scores | Schema only (step 8) | Hourly steps, 5-minute heart rate, daily resting heart rate. |
| `value_missing_reason` | Low | Derived | Explanations | Schema only (step 8) | Missing intervals are explicit (rule 12). |
| `source_record_id`, `source_updated_at_utc`, `idempotency_key` | Low | Health Connect, app | Idempotent import | Schema only (step 8) | Repeated imports never duplicate records (rule 7). |
| `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Storage | Schema only (step 8) | Bookkeeping; source deletions become tombstones. |

### `sleep_sessions`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `data_source_id` | Low | App | Sleep | Schema only (steps 7, 8) | Ownership and origin (manual entry or Health Connect). |
| `start_at_utc`, `start_time_zone`, `start_utc_offset_minutes`, `end_at_utc`, `end_time_zone`, `end_utc_offset_minutes` | Health | User or Health Connect | Rhythm engine, scores | Schema only (steps 7, 8) | Sleep timing and duration. |
| `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, `awake_minutes`, `stages_missing_reason` | Health | Health Connect | Rhythm engine | Schema only (step 8) | Sleep quality factors; explicit when the band reports no stages. |
| `source_record_id`, `source_updated_at_utc`, `idempotency_key`, `version` | Low | Health Connect, app | Idempotent import, sync | Schema only (steps 7, 8) | No duplicates; newer versions win. |
| `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Storage | Schema only (steps 7, 8) | Bookkeeping. |

### `activity_sessions`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `data_source_id`, `activity_type` | Health | User or Health Connect | Rhythm engine | Schema only (steps 7, 8) | Movement affects energy and recovery. |
| `start_at_utc`, `start_time_zone`, `start_utc_offset_minutes`, `end_at_utc`, `end_time_zone`, `end_utc_offset_minutes` | Health | User or Health Connect | Rhythm engine | Schema only (steps 7, 8) | Timing of the activity. |
| `intensity`, `intensity_missing_reason` | Health | User | Rhythm engine | Schema only (step 7) | Hard sessions need more recovery. |
| `source_record_id`, `source_updated_at_utc`, `idempotency_key`, `version` | Low | Health Connect, app | Idempotent import, sync | Schema only (steps 7, 8) | No duplicates; newer versions win. |
| `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Storage | Schema only (steps 7, 8) | Bookkeeping. |

### `device_usage_buckets`

Requires the `device_usage` consent (checked by the import repository) and the Android usage access
permission. Package names are mapped to a category on the phone and
discarded.

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `device_id` | Low | App | Usage aggregation | Schema only (step 9) | Ownership; which phone measured. |
| `bucket_start_at_utc`, `bucket_start_time_zone`, `bucket_start_utc_offset_minutes`, `bucket_duration_minutes` | Behavior | Phone | Rhythm engine | Schema only (step 9) | 30-minute slot. |
| `screen_on_seconds`, `unlock_count`, `app_switch_count` | Behavior | `UsageStatsManager` | Rhythm engine, overdrive detection | Schema only (step 9) | Fragmented attention and late screen use are rhythm factors. |
| `productivity_seconds`, `communication_seconds`, `social_seconds`, `entertainment_seconds`, `games_seconds`, `information_seconds`, `other_seconds` | Behavior | `UsageStatsManager`, categorized on the phone | Rhythm engine | Schema only (step 9) | What kind of use, without which apps. |
| `missing_reason` | Low | Derived | Explanations | Schema only (step 9) | Unmeasured slots are explicit, not zero. |
| `idempotency_key`, `source_updated_at_utc` | Low | App | Idempotent upload | Schema only (step 9) | Re-uploads never duplicate a slot. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Schema only (step 9) | Bookkeeping. |

### `check_ins`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id` | Identifier | Device | Check-in | Collected | Ownership; client-generated ID for offline sync. |
| `recorded_at_utc`, `recorded_time_zone`, `recorded_utc_offset_minutes` | Behavior | Device | Energy estimate | Collected | When the check-in happened, in UTC plus the original zone. |
| `self_reported_energy` | Health (self-report) | Manual check-in | Energy estimate | Collected | Main input of the estimate. |
| `sleep_duration_minutes` | Health | Manual check-in; Apple Health or Health Connect only with consent | Energy estimate | Collected | Secondary input of the estimate. |
| `sleep_duration_source` | Low | Derived | Energy estimate | Collected | Shows where the sleep value came from in explanations. |
| `self_reported_energy_missing_reason`, `sleep_duration_missing_reason` | Low | Derived | Energy estimate | Collected | Records why an input is absent instead of inventing it. |
| `version`, `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Sync | Collected | Optimistic concurrency and tombstones for offline sync. |

### `meal_events`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `meal_type`, `size`, `size_missing_reason` | Health (lifestyle) | User | Rhythm engine | Schema only (step 7) | Meal timing and size affect energy dips. No food descriptions. |
| `eaten_at_utc`, `eaten_time_zone`, `eaten_utc_offset_minutes` | Behavior | User | Rhythm engine | Schema only (step 7) | When the meal was eaten. |
| `version`, `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Sync | Schema only (step 7) | Bookkeeping. |

### `caffeine_events`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `amount`, `amount_missing_reason` | Health (lifestyle) | User | Rhythm engine, recommendations | Schema only (step 7) | Caffeine timing affects sleep and focus. No product names. |
| `consumed_at_utc`, `consumed_time_zone`, `consumed_utc_offset_minutes` | Behavior | User | Rhythm engine | Schema only (step 7) | When caffeine was consumed. |
| `version`, `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Sync | Schema only (step 7) | Bookkeeping. |

### `rest_events`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `rest_type` | Behavior | User | Rhythm engine | Schema only (step 7) | Breaks and naps support recovery. |
| `start_at_utc`, `start_time_zone`, `start_utc_offset_minutes`, `end_at_utc`, `end_time_zone`, `end_utc_offset_minutes` | Behavior | User | Rhythm engine | Schema only (step 7) | Timing of the rest. |
| `version`, `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Sync | Schema only (step 7) | Bookkeeping. |

### `focus_sessions`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `planned_duration_minutes`, `outcome` | Behavior | User | Focus sessions, rhythm engine | Schema only (step 7) | Planned versus actual focus. No task names. |
| `start_at_utc`, `start_time_zone`, `start_utc_offset_minutes`, `end_at_utc`, `end_time_zone`, `end_utc_offset_minutes` | Behavior | Device | Rhythm engine | Schema only (step 7) | When focus happened. |
| `self_rated_focus`, `self_rated_focus_missing_reason` | Health (self-report) | User | Rhythm engine | Schema only (step 7) | How the session felt. |
| `version`, `created_at_utc`, `updated_at_utc`, `deleted_at_utc` | Low | Generated | Sync | Schema only (step 7) | Bookkeeping. |

### `daily_scores`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `local_date`, `time_zone`, `score_type` | Low | Derived | Energy Score, Intensity Debt | Schema only (step 12) | Which day and score. |
| `status`, `score_value`, `input_coverage_ratio` | Derived health | Calculated | Energy Score, Intensity Debt | Schema only (step 12) | The non-medical score and how complete its inputs were. |
| `calculation_version`, `explanation`, `computed_at_utc` | Low | Calculated | Explanations | Schema only (step 12) | Every result explains its factors (rule 10). |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Schema only (step 12) | Bookkeeping. |

### `rhythm_buckets`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `bucket_start_at_utc`, `bucket_start_time_zone`, `bucket_start_utc_offset_minutes`, `bucket_duration_minutes` | Low | Derived | Rhythm engine | Schema only (step 11) | 30-minute slot of the day. |
| `status`, `state`, `energy_level`, `confidence_ratio` | Derived health | Calculated | Today dashboard | Schema only (step 11) | Estimated rhythm state and its confidence. |
| `calculation_version`, `explanation`, `computed_at_utc` | Low | Calculated | Explanations | Schema only (step 11) | Every result explains its factors (rule 10). |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Schema only (step 11) | Bookkeeping. |

### `recommendations`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `kind`, `template_key`, `parameters` | Derived | Calculated | Recommendations | Schema only (step 14) | Which suggestion to show; rendered from a template, never generated text. |
| `explanation`, `calculation_version` | Low | Calculated | Explanations | Schema only (step 14) | Input factors behind the suggestion (rule 10). |
| `valid_from_at_utc`, `valid_from_time_zone`, `valid_from_utc_offset_minutes`, `valid_until_at_utc` | Low | Calculated | Recommendations | Schema only (step 14) | When the suggestion applies. |
| `status`, `responded_at_utc` | Behavior | User | Recommendations | Schema only (step 14) | Whether suggestions help, to tune rules. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Schema only (step 14) | Bookkeeping. |

### `sync_checkpoints`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `device_id`, `stream`, `cursor`, `last_synced_at_utc` | Low | Server | Sync | Schema only (step 10) | Where each device continues pulling changes. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Schema only (step 10) | Bookkeeping. |

### `applied_sync_operations`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `operation_id`, `user_id`, `entity_type`, `entity_id`, `payload_fingerprint`, `result`, `applied_at_utc` | Low (contains result, not payload) | Generated | Sync | Collected | Makes retried operations idempotent. |

### `audit_events`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `action`, `entity_type`, `entity_id` | Low | Server | Accountability, security | Collected | Proves sign-ins, sign-outs, consent changes, exports and deletions happened. |
| `metadata` | Low (no health values) | Server | Accountability | Collected | Non-health context, e.g. the consent policy version. Never tokens, passwords, emails, or IP addresses. |
| `occurred_at_utc`, `created_at_utc` | Low | Server | Accountability | Collected | When it happened. |

### `data_export_jobs`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `user_id`, `status`, `requested_at_utc`, `started_at_utc`, `completed_at_utc`, `expires_at_utc`, `failure_code` | Low | Server | Data export | Collected | Tracks the export the user asked for. |
| `result`, `result_bytes` | Health (copy of all account data) | Server | Data export | Collected | The export file. Removed 7 days after completion; the job row after 30 days. |
| `created_at_utc`, `updated_at_utc` | Low | Generated | Storage | Collected | Bookkeeping. |

## Consent types

Decision [0014](../architecture/0014-consent-types-export-and-deletion.md):

| Consent type | Covers | Stores data |
| --- | --- | --- |
| `health_data` | One external source (`health_connect`, `apple_health`) with scopes `sleep_duration`, `steps`, `heart_rate`, `resting_heart_rate` | Imported health records |
| `device_usage` | Usage aggregates from the phone | `device_usage_buckets` |
| `notifications` | Reminders and suggestions as notifications | Nothing |
| `analytics` | Product analytics (none is collected yet) | Nothing |

The import repositories refuse new data the moment the matching consent is
missing, withdrawn, or granted under an older consent text. Withdrawing can
also delete the data already collected for that type.

## On the phone

The Android app keeps its own encrypted SQLite database
([0015](../architecture/0015-flutter-app-architecture.md)). The file is
encrypted with SQLite3MultipleCiphers (ChaCha20-Poly1305); Android backup is
disabled, so neither the database nor its key leaves the phone. "Delete data
on this phone" in the app signs out and empties every table below; the
database key, which protects nothing once the tables are empty, stays. Signing
out removes the account data (consent decisions and the write queue) and keeps
the preferences.
`apps/mobile/test/core/database/data_inventory_test.dart` fails if a local
column is missing here.

### Phone table `local_settings`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id` | Low | App | Storage | Collected | Always 1: the table has exactly one row. |
| `theme_preference`, `language_preference` | Low | User | Settings | Collected | Light or dark theme and app language, or "follow the system". |
| `onboarding_completed_at_utc` | Low | App | First start | Collected | Shows the welcome flow only once. |

### Phone table `consent_decisions`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `consent_type`, `source_id`, `state`, `scopes`, `policy_version` | Consent record | User | Consent | Collected | The user's decisions, applied on the phone at once and uploaded when signed in. Same fields as the server table. |
| `decided_at_utc`, `decided_time_zone`, `decided_utc_offset_minutes` | Low | Device clock and time zone | Consent | Collected | When the decision was made (rule 9). |
| `synced_at_utc` | Low | App | Sync | Collected | Whether the server has the decision. |

### Phone table `outbox_operations`

| Fields | Sensitivity | Source | Feature | Status | Why it is needed |
| --- | --- | --- | --- | --- | --- |
| `id`, `kind`, `payload` | Same as the queued record | App | Offline write queue | Collected | A change waiting for upload; the ID is the record ID, so uploads are idempotent. Today only consent decisions are queued. |
| `created_at_utc`, `attempts`, `next_attempt_at_utc`, `status` | Low | App | Offline write queue | Collected | Order, retry with backoff, and refused changes. |
| `last_error` | Low | App | Offline write queue | Collected | A stable error code such as `validation_failed:scopes`; never a server message or record content. |

### Phone secure storage

Kept in `flutter_secure_storage` (Android Keystore), never in preferences or
files:

| Key | Contents | Removed |
| --- | --- | --- |
| `flowwave.auth.tokens.v1` | Access and refresh token with their expiry times | At sign-out and account deletion. |
| `flowwave.database.key.v1` | Random 256-bit key of the local database | When local data is deleted after a lost key; otherwise kept with the app. |

## Held in memory only

The rate limiter keeps a counter per client IP address and per hashed email
for at most one limit window (decision 0013). IP addresses are not written to
the database, audit events, or logs.

## Declared external sources (not yet integrated)

| Source | Scopes FlowWave may request | Status |
| --- | --- | --- |
| Apple Health | `sleep_duration`, `steps`, `heart_rate`, `resting_heart_rate` | Declared only; no adapter exists, nothing is collected. |
| Health Connect | `sleep_duration`, `steps`, `heart_rate`, `resting_heart_rate` | Declared only; no adapter exists, nothing is collected. Step 8 adds the adapter and any further scopes (exercise). |

## Deletion

Deleting a user row cascades to every table that has a `user_id`, except
`audit_events`, where `user_id` becomes NULL and the event stays without
personal data. Covered by `db/tests/01_ported_constraints.test.sql` and
`db/tests/02_data_model.test.sql`.

`DELETE /v1/account` (current password required) deletes the user row in one
transaction and returns the ID of the `account_deleted` audit event as a
receipt. There is no grace period. Covered by `apps/api/test/account.test.ts`.

An hourly retention job removes ended sessions after 30 days, export files
after 7 days, export jobs after 30 days, and tombstones (`deleted_at_utc`) of
records and events after 90 days. Devices and data sources are kept while the
account exists, because records refer to them.
