# Data dictionary

Every table and column in the FlowWave database, with type, unit and meaning.
Source of truth: [`apps/api/prisma/schema.prisma`](../../apps/api/prisma/schema.prisma)
and the CHECK constraints in
[`apps/api/prisma/migrations`](../../apps/api/prisma/migrations). Design
decisions: [0012](../architecture/0012-data-model.md),
[0013](../architecture/0013-authentication-and-sessions.md) (accounts and
sessions), [0014](../architecture/0014-consent-types-export-and-deletion.md)
(consent types, export, deletion). Relations:
[ER diagram](er-diagram.md). Why each field is collected and how sensitive it
is: [data inventory](../privacy/data-inventory.md).

`apps/api/test/dataDictionary.test.ts` fails if a column in the schema is
missing here.

## Conventions

- **Keys**: `id` is a UUID. Rows created on a device get their ID there
  (offline-first); others get `gen_random_uuid()`.
- **Event times**: `<name>_at_utc` is the instant in UTC; `<name>_time_zone`
  is the IANA zone where it happened; `<name>_utc_offset_minutes` is the
  offset in that zone at that instant (−840 to 840).
- **Missing values**: a nullable value with a `*_missing_reason` partner holds
  either a value or a reason, never both and never neither. A NULL value never
  means zero.
- **Bookkeeping**: `created_at_utc` is when the row was stored;
  `updated_at_utc` is maintained by a trigger; `deleted_at_utc` is a tombstone
  (soft deletion); `version` starts at 1 and increases with every change that
  synchronizes.
- **Imports**: `idempotency_key` identifies an import per user;
  `source_record_id` is the Health Connect record ID; `source_updated_at_utc`
  is the modification time at the source and orders versions.

## Enums

| Type | Values |
| --- | --- |
| `missing_reason` | `not_recorded`, `user_skipped`, `no_consent`, `source_unavailable`, `not_yet_synced` |
| `check_in_sleep_source` | `manual_check_in`, `apple_health`, `health_connect` |
| `device_platform` | `android`, `ios`, `web`, `windows` |
| `health_source_kind` | `manual_entry`, `health_connect`, `apple_health`, `synthetic` (seed and test data only) |
| `health_metric` | `steps`, `heart_rate`, `resting_heart_rate` |
| `measurement_unit` | `count`, `beats_per_minute` |
| `activity_type` | `walking`, `running`, `cycling`, `strength_training`, `sports`, `other` |
| `activity_intensity` | `light`, `moderate`, `hard` |
| `meal_type` | `breakfast`, `lunch`, `dinner`, `snack`, `other` |
| `portion_size` | `small`, `medium`, `large` |
| `rest_type` | `short_break`, `nap`, `relaxation`, `outdoor_break`, `other` |
| `focus_outcome` | `completed`, `ended_early`, `interrupted` |
| `score_type` | `energy`, `intensity_debt` |
| `calculation_status` | `computed`, `insufficient_data` |
| `rhythm_state` | `ready`, `flow`, `recovery`, `overdrive` |
| `recommendation_kind` | `focus_block`, `break`, `wind_down`, `meal_timing`, `movement`, `caffeine_timing` |
| `recommendation_status` | `active`, `accepted`, `dismissed`, `expired` |
| `audit_action` | `account_created`, `account_deleted`, `consent_recorded`, `device_registered`, `device_revoked`, `data_exported`, `data_deleted`, `login_succeeded`, `login_failed`, `logged_out`, `logged_out_all`, `session_revoked`, `refresh_token_reused`, `data_export_requested` |
| `consent_type` | `health_data`, `device_usage`, `notifications`, `analytics` |
| `session_revocation_reason` | `logout`, `logout_all`, `revoked_by_user`, `refresh_token_reused` |
| `export_job_status` | `pending`, `running`, `completed`, `failed`, `expired` |

## `users` (User)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Account identifier. |
| `home_time_zone` | varchar(64) | no | IANA zone | Default zone for showing days and scheduling. |
| `sleep_goal_minutes` | smallint | yes | minutes, 180–900 | The user's own sleep goal; NULL until set, never defaulted. |
| `is_synthetic` | boolean | no | | True only for seed and test accounts; excluded from pilot analysis. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

Deleting a user deletes every row below that has its `user_id` (cascade),
except `audit_events`, where `user_id` becomes NULL.

## `user_credentials` (UserCredential)

Email and password sign-in (development authentication, decision 0013). One
row per user; accounts without a password (future sign-in methods) have none.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `user_id` | uuid | no | | Account (primary key). |
| `email` | varchar(254) | no | lower-case, trimmed | Sign-in name; unique. Never written to logs or audit events. |
| `password_hash` | text | no | Argon2id PHC string | `$argon2id$v=19$m=…,t=…,p=…$salt$hash`. Never exported, logged, or returned. |
| `password_updated_at_utc` | timestamptz | no | UTC | Password last set (not changed by a rehash). |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

## `auth_sessions` (AuthSession)

One signed-in device. Created by sign-in together with a `devices` row.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Session identifier. |
| `user_id` | uuid | no | | Owner. |
| `device_id` | uuid | no | | Device signed in by this session; same user; one session per device. |
| `expires_at_utc` | timestamptz | no | UTC, after `created_at_utc` | End of the newest refresh token; moves forward on every refresh. |
| `last_refreshed_at_utc` | timestamptz | yes | UTC | Last token refresh; NULL until the first one. |
| `revoked_at_utc` | timestamptz | yes | UTC | Signed out; set together with `revoked_reason`. |
| `revoked_reason` | session_revocation_reason | yes | enum | Why the session ended. |
| `created_at_utc` | timestamptz | no | UTC | Signed in. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

Deleted 30 days after it was revoked or expired (retention, decision 0014).

## `auth_tokens` (AuthToken)

One access token and one refresh token, issued together. Only SHA-256 hashes
are stored; a trigger allows no change except setting `rotated_at_utc` once.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Token pair identifier. |
| `user_id` | uuid | no | | Owner. |
| `session_id` | uuid | no | | Session; same user. |
| `access_token_hash` | varchar(64) | no | lower-case hex | SHA-256 of the access token; unique. |
| `access_expires_at_utc` | timestamptz | no | UTC | Access token expiry (15 minutes by default). |
| `refresh_token_hash` | varchar(64) | no | lower-case hex | SHA-256 of the refresh token; unique. |
| `refresh_expires_at_utc` | timestamptz | no | UTC, ≥ access expiry | Refresh token expiry (30 days by default). |
| `rotated_at_utc` | timestamptz | yes | UTC | The refresh token was used; presenting it again revokes the session. |
| `created_at_utc` | timestamptz | no | UTC | Issued. |

## `devices` (Device)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Installation of a FlowWave app. |
| `user_id` | uuid | no | | Owner. |
| `platform` | device_platform | no | enum | Operating system family. |
| `app_version` | varchar(32) | yes | | FlowWave app version, for sync compatibility. |
| `last_seen_at_utc` | timestamptz | yes | UTC | Last successful contact. |
| `created_at_utc` | timestamptz | no | UTC | Registered. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Signed out; its data stays with the user. |

No hardware identifiers (IMEI, serial number, advertising ID) are stored.

## `consent_decisions` (Consent)

Append-only: a withdrawal is a new row; UPDATE is rejected by a trigger. The
ID is generated on the device, so repeating a decision is safe.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Decision identifier. |
| `user_id` | uuid | no | | Who decided. |
| `consent_type` | consent_type | no | enum | What the decision is about (decision 0014). |
| `source_id` | text | yes | `apple_health`, `health_connect` | External source; set exactly when `consent_type` is `health_data`. |
| `state` | text | no | `granted`, `revoked` | The decision. |
| `scopes` | text[] | no (CHECK) | `sleep_duration`, `steps`, `heart_rate`, `resting_heart_rate` | Granted health data categories; empty for a withdrawal and for other types. |
| `policy_version` | varchar(32) | no | | Consent text version the user saw. |
| `decided_at_utc` | timestamptz | no | UTC | When the user decided. |
| `decided_time_zone` | varchar(64) | no | IANA zone | Zone at decision time. |
| `decided_utc_offset_minutes` | smallint | no | minutes | Offset at decision time. |
| `created_at_utc` | timestamptz | no | UTC | Row stored. |

## `health_data_sources` (HealthDataSource)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Source identifier. |
| `user_id` | uuid | no | | Owner. |
| `kind` | health_source_kind | no | enum | How the data arrives. |
| `source_key` | varchar(200) | no | starts with `kind` | Deterministic client key, e.g. `health_connect:com.mi.health`; unique per user. |
| `provider_package` | varchar(200) | yes | Android package | Health app that wrote the data to Health Connect. Health providers only. |
| `provider_name` | varchar(100) | yes | | Display name of the provider, e.g. Mi Fitness. |
| `recording_device_type` | varchar(32) | yes | Health Connect device types | `watch`, `phone`, `fitness_band`, `ring`, ... |
| `recording_device_manufacturer` | varchar(100) | yes | | Manufacturer reported by Health Connect. |
| `recording_device_model` | varchar(100) | yes | | Model reported by Health Connect. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Disconnected by the user. |

## `health_samples` (HealthSample)

Aggregates only: steps per hour, heart rate per 5 minutes, resting heart rate
per day. Raw per-step or per-beat samples are never stored.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Sample identifier. |
| `user_id` | uuid | no | | Owner. |
| `data_source_id` | uuid | no | | Source; must belong to the same user. |
| `metric` | health_metric | no | enum | What was measured. |
| `unit` | measurement_unit | no | `count` for steps, `beats_per_minute` for heart rates | Unit of the value columns. |
| `start_at_utc` | timestamptz | no | UTC | Interval start. |
| `start_time_zone` | varchar(64) | no | IANA zone | Zone at start. |
| `start_utc_offset_minutes` | smallint | no | minutes | Offset at start. |
| `end_at_utc` | timestamptz | no | UTC | Interval end: 1 hour (steps), 5 minutes (heart rate), ≤ 1 day (resting). |
| `end_time_zone` | varchar(64) | no | IANA zone | Zone at end. |
| `end_utc_offset_minutes` | smallint | no | minutes | Offset at end. |
| `value` | double | yes | `unit`; steps 0–100000 whole, heart rate 20–250 | Sum (steps), average (heart rate) or value (resting heart rate). |
| `min_value` | double | yes | `unit` | Heart rate only: minimum in the interval. |
| `max_value` | double | yes | `unit` | Heart rate only: maximum in the interval. |
| `sample_count` | integer | yes | count | Number of underlying samples, if known. |
| `value_missing_reason` | missing_reason | yes | enum | Why there is no value for this interval. |
| `source_record_id` | varchar(200) | yes | | Health Connect record ID; NULL for aggregate API values. |
| `source_updated_at_utc` | timestamptz | no | UTC | Modification time at the source. |
| `idempotency_key` | varchar(200) | no | | Import identity, unique per user. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Deleted at the source. |

## `sleep_sessions` (SleepSession)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Session identifier. |
| `user_id` | uuid | no | | Owner. |
| `data_source_id` | uuid | no | | Source (Health Connect, manual entry); same user. |
| `start_at_utc` | timestamptz | no | UTC | Fell asleep (or went to bed, as reported). |
| `start_time_zone` | varchar(64) | no | IANA zone | Zone at start. |
| `start_utc_offset_minutes` | smallint | no | minutes | Offset at start. |
| `end_at_utc` | timestamptz | no | UTC | Woke up; at most 24 hours after start. |
| `end_time_zone` | varchar(64) | no | IANA zone | Zone at end. |
| `end_utc_offset_minutes` | smallint | no | minutes | Offset at end. |
| `deep_sleep_minutes` | smallint | yes | minutes | Deep sleep, if reported. |
| `light_sleep_minutes` | smallint | yes | minutes | Light sleep, if reported. |
| `rem_sleep_minutes` | smallint | yes | minutes | REM sleep, if reported. |
| `awake_minutes` | smallint | yes | minutes | Awake time within the session, if reported. Stages together fit in the session. |
| `stages_missing_reason` | missing_reason | yes | enum | Set when no stage was reported at all. |
| `source_record_id` | varchar(200) | yes | | Health Connect record ID. |
| `source_updated_at_utc` | timestamptz | no | UTC | Modification time at the source. |
| `idempotency_key` | varchar(200) | no | | Import identity, unique per user. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Deleted by the user or at the source. |

## `activity_sessions` (ActivitySession)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Session identifier. |
| `user_id` | uuid | no | | Owner. |
| `data_source_id` | uuid | no | | Source; same user. |
| `activity_type` | activity_type | no | enum | Kind of activity. |
| `start_at_utc` | timestamptz | no | UTC | Start. |
| `start_time_zone` | varchar(64) | no | IANA zone | Zone at start. |
| `start_utc_offset_minutes` | smallint | no | minutes | Offset at start. |
| `end_at_utc` | timestamptz | no | UTC | End; at most 24 hours after start. |
| `end_time_zone` | varchar(64) | no | IANA zone | Zone at end. |
| `end_utc_offset_minutes` | smallint | no | minutes | Offset at end. |
| `intensity` | activity_intensity | yes | enum | User-rated or derived intensity. |
| `intensity_missing_reason` | missing_reason | yes | enum | Why intensity is unknown (Health Connect does not provide it). |
| `source_record_id` | varchar(200) | yes | | Health Connect record ID. |
| `source_updated_at_utc` | timestamptz | no | UTC | Modification time at the source. |
| `idempotency_key` | varchar(200) | no | | Import identity, unique per user. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Tombstone. |

No GPS routes, calories or distance.

## `device_usage_buckets` (DeviceUsageBucket)

Screen use per 30-minute bucket. Package names are mapped to categories in
memory on the phone and discarded; they never reach the database.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Bucket identifier. |
| `user_id` | uuid | no | | Owner. |
| `device_id` | uuid | no | | Phone that measured; same user. |
| `bucket_start_at_utc` | timestamptz | no | UTC, aligned to :00 or :30 | Bucket start; unique per device. |
| `bucket_start_time_zone` | varchar(64) | no | IANA zone | Zone at bucket start. |
| `bucket_start_utc_offset_minutes` | smallint | no | minutes | Offset at bucket start. |
| `bucket_duration_minutes` | smallint | no | minutes, always 30 | Bucket length. |
| `missing_reason` | missing_reason | yes | enum | Set when the bucket could not be measured; then every metric is NULL. |
| `screen_on_seconds` | integer | yes | seconds, 0–1800 | Time the screen was on. |
| `unlock_count` | integer | yes | count | Unlocks (keyguard dismissed). |
| `app_switch_count` | integer | yes | count | Changes of the foreground app. |
| `productivity_seconds` | integer | yes | seconds | Foreground time in productivity apps. |
| `communication_seconds` | integer | yes | seconds | Foreground time in communication apps (no message content). |
| `social_seconds` | integer | yes | seconds | Foreground time in social apps. |
| `entertainment_seconds` | integer | yes | seconds | Foreground time in video and music apps. |
| `games_seconds` | integer | yes | seconds | Foreground time in games. |
| `information_seconds` | integer | yes | seconds | Foreground time in news, reading and browser apps (no URLs). |
| `other_seconds` | integer | yes | seconds | Everything else. Category seconds together ≤ `screen_on_seconds`. |
| `idempotency_key` | varchar(200) | no | | Import identity, unique per user. |
| `source_updated_at_utc` | timestamptz | no | UTC | When the phone computed the bucket. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

## `check_ins` (SelfCheckIn)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Generated on the device. |
| `user_id` | uuid | no | | Owner. |
| `recorded_at_utc` | timestamptz | no | UTC | When the check-in was made. |
| `recorded_time_zone` | varchar(64) | no | IANA zone | Zone at that time. |
| `recorded_utc_offset_minutes` | smallint | no | minutes | Offset at that time. |
| `self_reported_energy` | smallint | yes | scale 1–5 | Energy estimate version 1 input. |
| `self_reported_energy_missing_reason` | missing_reason | yes | enum | Why energy is absent. |
| `sleep_duration_minutes` | smallint | yes | minutes, 0–1440 | Sleep before the check-in. |
| `sleep_duration_source` | check_in_sleep_source | yes | enum | Where the sleep value came from; set iff the value is. |
| `sleep_duration_missing_reason` | missing_reason | yes | enum | Why sleep is absent. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Tombstone. |

## `meal_events` (MealEvent)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Generated on the device. |
| `user_id` | uuid | no | | Owner. |
| `eaten_at_utc` | timestamptz | no | UTC | When the meal was eaten. |
| `eaten_time_zone` | varchar(64) | no | IANA zone | Zone at that time. |
| `eaten_utc_offset_minutes` | smallint | no | minutes | Offset at that time. |
| `meal_type` | meal_type | no | enum | Which meal. |
| `size` | portion_size | yes | enum | Rough size chosen by the user. |
| `size_missing_reason` | missing_reason | yes | enum | Why size is absent. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Tombstone. |

No food descriptions, photos or calories.

## `caffeine_events` (CaffeineEvent)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Generated on the device. |
| `user_id` | uuid | no | | Owner. |
| `consumed_at_utc` | timestamptz | no | UTC | When caffeine was consumed. |
| `consumed_time_zone` | varchar(64) | no | IANA zone | Zone at that time. |
| `consumed_utc_offset_minutes` | smallint | no | minutes | Offset at that time. |
| `amount` | portion_size | yes | enum | Rough amount. |
| `amount_missing_reason` | missing_reason | yes | enum | Why the amount is absent. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Tombstone. |

No product names.

## `rest_events` (RestEvent)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Generated on the device. |
| `user_id` | uuid | no | | Owner. |
| `rest_type` | rest_type | no | enum | Kind of rest. |
| `start_at_utc` | timestamptz | no | UTC | Start. |
| `start_time_zone` | varchar(64) | no | IANA zone | Zone at start. |
| `start_utc_offset_minutes` | smallint | no | minutes | Offset at start. |
| `end_at_utc` | timestamptz | yes | UTC | End; NULL while in progress. |
| `end_time_zone` | varchar(64) | yes | IANA zone | Zone at end; set together with the end. |
| `end_utc_offset_minutes` | smallint | yes | minutes | Offset at end. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Tombstone. |

## `focus_sessions` (FocusSession)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Generated on the device. |
| `user_id` | uuid | no | | Owner. |
| `start_at_utc` | timestamptz | no | UTC | Start. |
| `start_time_zone` | varchar(64) | no | IANA zone | Zone at start. |
| `start_utc_offset_minutes` | smallint | no | minutes | Offset at start. |
| `end_at_utc` | timestamptz | yes | UTC | End; NULL while in progress. |
| `end_time_zone` | varchar(64) | yes | IANA zone | Zone at end. |
| `end_utc_offset_minutes` | smallint | yes | minutes | Offset at end. |
| `planned_duration_minutes` | smallint | yes | minutes, 1–720 | The user's plan; NULL means no plan. |
| `outcome` | focus_outcome | yes | enum | How the session ended; set iff it ended. |
| `self_rated_focus` | smallint | yes | scale 1–10 | Rating asked at the end. |
| `self_rated_focus_missing_reason` | missing_reason | yes | enum | Why the rating is absent after the end. |
| `version` | integer | no | ≥ 1 | Change counter for sync. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |
| `deleted_at_utc` | timestamptz | yes | UTC | Tombstone. |

No task names, documents or app names.

## `daily_scores` (DailyScore)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Result identifier. |
| `user_id` | uuid | no | | Owner. |
| `local_date` | date | no | | Calendar day in `time_zone`. |
| `time_zone` | varchar(64) | no | IANA zone | Zone that defines the day. |
| `score_type` | score_type | no | enum | Which score. |
| `status` | calculation_status | no | enum | `insufficient_data` when inputs were not enough. |
| `score_value` | double | yes | 0–100 | The score; NULL iff insufficient data. Not a medical measure. |
| `input_coverage_ratio` | double | no | ratio 0–1 | Share of expected inputs that were present. |
| `calculation_version` | varchar(32) | no | semver | Algorithm version that produced the result. |
| `explanation` | jsonb | no | object with `factors` and `disclaimer` | Factors used and missing, and the non-medical disclaimer. |
| `computed_at_utc` | timestamptz | no | UTC | When the result was computed. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

Unique per user, day, score type and calculation version.

## `rhythm_buckets` (RhythmBucket)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Result identifier. |
| `user_id` | uuid | no | | Owner. |
| `bucket_start_at_utc` | timestamptz | no | UTC, aligned to :00 or :30 | Slot start. |
| `bucket_start_time_zone` | varchar(64) | no | IANA zone | Zone at slot start. |
| `bucket_start_utc_offset_minutes` | smallint | no | minutes | Offset at slot start. |
| `bucket_duration_minutes` | smallint | no | minutes, always 30 | Slot length. |
| `status` | calculation_status | no | enum | `insufficient_data` when inputs were not enough. |
| `state` | rhythm_state | yes | enum | Estimated state; NULL when insufficient data. |
| `energy_level` | double | yes | 0–100 | Estimated energy level. |
| `confidence_ratio` | double | yes | ratio 0–1 | Confidence of the estimate. |
| `calculation_version` | varchar(32) | no | semver | Algorithm version. |
| `explanation` | jsonb | no | object with `factors` and `disclaimer` | Why this state was estimated. |
| `computed_at_utc` | timestamptz | no | UTC | When computed. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

## `recommendations` (Recommendation)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Recommendation identifier. |
| `user_id` | uuid | no | | Owner. |
| `kind` | recommendation_kind | no | enum | Category of suggestion. |
| `template_key` | varchar(100) | no | dotted lowercase key | Text template rendered by the client. |
| `parameters` | jsonb | no | object, ≤ 2 KB | Values filled into the template. |
| `explanation` | jsonb | no | object with `factors` and `disclaimer` | Input factors behind the suggestion. |
| `valid_from_at_utc` | timestamptz | no | UTC | Shown from. |
| `valid_from_time_zone` | varchar(64) | no | IANA zone | Zone for showing the time. |
| `valid_from_utc_offset_minutes` | smallint | no | minutes | Offset at `valid_from_at_utc`. |
| `valid_until_at_utc` | timestamptz | no | UTC | Expires at. |
| `status` | recommendation_status | no | enum | User response. |
| `responded_at_utc` | timestamptz | yes | UTC | Set iff accepted or dismissed. |
| `calculation_version` | varchar(32) | no | semver | Rule set version. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

## `sync_checkpoints` (SyncCheckpoint)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Checkpoint identifier. |
| `user_id` | uuid | no | | Owner. |
| `device_id` | uuid | no | | Device; same user. |
| `stream` | varchar(63) | no | lowercase identifier | Entity stream, e.g. `check_in`; unique per device. |
| `cursor` | varchar(200) | no | opaque | Server position returned to the device on the next pull. |
| `last_synced_at_utc` | timestamptz | no | UTC | Last successful sync of this stream. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

## `applied_sync_operations` (AppliedSyncOperation)

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `operation_id` | uuid | no | | Client-generated operation ID (primary key). |
| `user_id` | uuid | no | | Owner. |
| `entity_type` | text | no | lowercase identifier | Entity the operation changed. |
| `entity_id` | uuid | no | | Changed entity. |
| `payload_fingerprint` | text | no | | Canonical fingerprint of the payload; detects reused IDs. |
| `result` | jsonb | no | | Result returned on replay (not the payload). |
| `applied_at_utc` | timestamptz | no | UTC | When applied. |

## `data_export_jobs` (DataExportJob)

Account data exports (decision 0014). A CHECK keeps the columns consistent
with `status`.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Job identifier. |
| `user_id` | uuid | no | | Whose data is exported. |
| `status` | export_job_status | no | enum | `pending` → `running` → `completed` or `failed`; `completed` → `expired`. |
| `requested_at_utc` | timestamptz | no | UTC | Requested. |
| `started_at_utc` | timestamptz | yes | UTC | Claimed by the worker. |
| `completed_at_utc` | timestamptz | yes | UTC | Finished or failed. |
| `expires_at_utc` | timestamptz | yes | UTC | The file is removed after this (7 days). |
| `failure_code` | varchar(63) | yes | lowercase identifier | `export_failed` or `export_interrupted`; never an error message. |
| `result` | jsonb | yes | object | The export file while `completed`; contains health data. |
| `result_bytes` | integer | yes | bytes, ≥ 0 | Size of the file. |
| `created_at_utc` | timestamptz | no | UTC | Row created. |
| `updated_at_utc` | timestamptz | no | UTC | Row last changed. |

Jobs are deleted 30 days after they were requested.

## `audit_events` (AuditEvent)

Append-only; never contains health values.

| Column | Type | Null | Unit / values | Description |
| --- | --- | --- | --- | --- |
| `id` | uuid | no | | Event identifier. |
| `user_id` | uuid | yes | | Subject; NULL after the user is deleted. |
| `action` | audit_action | no | enum | What happened. |
| `entity_type` | varchar(63) | yes | lowercase identifier | Affected entity type; set together with `entity_id`. |
| `entity_id` | uuid | yes | | Affected entity. |
| `metadata` | jsonb | no | object, ≤ 2 KB | Non-health context, e.g. consent policy version. Never tokens, passwords, emails, or IP addresses. |
| `occurred_at_utc` | timestamptz | no | UTC | When it happened (server time). |
| `created_at_utc` | timestamptz | no | UTC | Row stored. |
