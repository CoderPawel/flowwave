# Data flow

- Status: Accepted for the MVP
- Last updated: 2026-11-27

How data enters FlowWave, where it is stored, how it is turned into estimates,
and how it is synchronized. Components are described in the
[system overview](system-overview.md).

## Data by location

| Data | Origin | On device | Server (only if sync is on) | Never stored |
| --- | --- | --- | --- | --- |
| Energy and focus check-ins | User | Yes | Yes | |
| Meals (time, size) | User | Yes | Yes | Food descriptions, photos, calories |
| Caffeine (time, rough amount: small / medium / large) | User | Yes | Yes | Product names |
| Exercise (start, end, intensity: light / moderate / hard) | User or Health Connect | Yes | Yes | GPS routes |
| Rest and breaks (start, end) | User | Yes | Yes | |
| Sleep sessions (start, end, stages if available) | Health Connect or user | Yes | Yes | |
| Steps | Health Connect | Hourly totals | Hourly totals | Per-step samples |
| Heart rate | Health Connect | 5-minute min / average / max; daily resting value | Same | Raw beat-level samples |
| Screen use | `UsageStatsManager` | Per 30 minutes: screen-on time, unlocks, app switches, time per app category | Same | Package names, app names, raw events |
| Consent decisions | User | Yes | Yes | |
| Estimates and suggestions | Computed on device | Recomputed on demand; cached | No (recomputed from inputs) | |

Each row gets a [data inventory](../privacy/data-inventory.md) entry in the
phase that implements it.

## Manual check-ins and life events

The user's tap is stored locally first, together with an outbox entry, in one
database transaction ([0007](0007-android-offline-first-storage.md)). Sync is
a separate, optional step.

```mermaid
sequenceDiagram
    actor U as User
    participant UI as Android UI (notification, widget, app)
    participant DB as On-device database
    participant W as Sync worker (WorkManager)
    participant API as Sync API
    participant PG as PostgreSQL

    U->>UI: Rate energy 4, focus 3
    UI->>DB: One transaction: insert check_in and outbox operation
    UI-->>U: Saved (works offline)
    Note over W: Runs only if sync is on and network is available
    W->>DB: Read pending operations (oldest first)
    W->>API: POST /v1/sync/operations (batch)
    API->>PG: One transaction: apply change and record operation_id
    API-->>W: applied or replayed, per operation
    W->>DB: Remove acknowledged operations from outbox
```

Skipping a check-in creates no row. When the estimate needs that input, it is
represented as missing with reason `user_skipped` or `not_recorded`
([0002](0002-time-and-missing-data.md)).

## Health Connect import

```mermaid
sequenceDiagram
    participant W as Import worker (hourly, WorkManager)
    participant HC as Health Connect
    participant M as Mapper and validator
    participant DB as On-device database

    W->>W: Check consent log and granted HC permissions per data type
    alt permission missing or consent revoked
        W->>DB: Record data type as missing (no_consent), skip this type
    else permitted
        W->>HC: getChanges(token for this data type)
        alt token valid
            HC-->>W: inserted / updated / deleted records, next token
        else token expired (unused for 30 days)
            W->>HC: readRecords(from last imported time, max 30 days, paged)
            HC-->>W: records
        end
        W->>M: Records with HC id, data origin, zone offset
        M->>M: Validate ranges, aggregate steps per hour and heart rate per 5 min
        M->>DB: Upsert by (data type, HC record id), apply deletions
        W->>DB: Store next token and last imported time
    end
```

Rules:

- One changes token per data type, so revoking one permission does not break
  the others.
- Records are keyed by Health Connect record ID, so re-reading after token
  expiry creates no duplicates.
- Steps are read through the Health Connect aggregate API, which applies the
  user's data-source priority, so phone and band steps are not double counted.
- A night without a sleep record is stored as missing (`not_recorded` or
  `source_unavailable`), never as zero sleep.
- Health Connect records include a zone offset; FlowWave stores the UTC instant,
  that offset, and the device's IANA time zone at import time.
- FlowWave never writes to Health Connect in the MVP.

## Screen-use aggregation

```mermaid
flowchart LR
    ev["UsageStatsManager.queryEvents (since last run)"] --> filter["Keep screen, keyguard, and foreground-app events"]
    filter --> intervals["Build screen-on intervals in memory, map each foreground package to a category with a local table"]
    intervals --> buckets["Split into 30-minute buckets: screen-on seconds, unlocks, app switches, seconds per category"]
    buckets --> db[("On-device database")]
    intervals -. "package names after categorizing, all other event types" .-> drop["Discarded in memory, never stored"]
```

- Runs at least every few hours, because Android keeps usage events only for a
  limited number of days.
- Needs the user to grant Usage access in system settings. Without it, screen
  use is missing with reason `no_consent`.
- Per-app breakdowns are out of scope. Per-category totals were added by the
  owner's plan (roadmap step 9); the storage format is decided in
  [0012](0012-data-model.md) (`device_usage_buckets`), and step 9 implements the
  collection.

## Estimates and suggestions

```mermaid
flowchart LR
    inputs["Inputs for a time window: check-ins, sleep, life events, steps, heart rate, screen use"] --> m["Each input: present (value, source, time) or missing (reason)"]
    m --> rules["Domain rules: estimate, load, rhythm"]
    rules --> out["Result: score or insufficient_data, factors used, factors missing, history length, suggestion, disclaimer"]
```

- Computed on the device, so it works offline. The server does not compute
  estimates in the MVP.
- Results are derived data: they can always be recomputed from inputs and are
  not synchronized.

## Synchronization, deletion, export

- Sync is off until the user creates an account and turns it on.
- Operations follow [0004](0004-offline-first-idempotent-sync.md): the
  client generates the operation ID; the server replays results for repeated IDs
  and rejects reused IDs with a different payload.
- Deleting an entry creates a tombstone that syncs like any other change.
- Turning sync off keeps local data and stops uploads. Deleting the account
  (`DELETE /v1/account`, current password required) deletes all server data
  for that user in one transaction and returns a deletion receipt
  ([0014](0014-consent-types-export-and-deletion.md)).
- The server export (`POST /v1/account/exports`) is a background job that
  writes all server data of the user as JSON (format
  `flowwave-account-export`, version 1, keyed by table and column names, no
  password or token hashes) and keeps it for 7 days. Data that exists only on
  the phone gets its own export with the local database in later steps.
- Withdrawing consent stops server imports of that data at once; the user can
  also have the data collected under it deleted.
- Signing out deletes the tokens and all registered local account data on the
  phone ([0013](0013-authentication-and-sessions.md)).

## Time handling

- The device captures the instant in UTC, the IANA time zone, and the offset
  at the moment of the event.
- Local-day views use the zone stored with each event, so travel does not
  rewrite history.

## Assumptions

- Mi Fitness writes sleep sessions, steps, and heart rate to Health Connect on
  the owner's phone.
- Hourly background import is enough for day planning; the user can also
  refresh manually.

## Risks

| Risk | Mitigation |
| --- | --- |
| Health Connect read quotas, stricter in the background | Changes API instead of full re-reads; batch per data type; back off on quota errors. |
| Wearable data arrives late (Mi Fitness syncs irregularly) | Imports are idempotent and estimates are recomputed when late data arrives. |
| Usage events expire before collection | Collector runs several times a day; a gap is stored as missing. |
| Duplicate steps from several sources | Aggregate API with Health Connect data-source priority. |

## Non-goals

- Server-side analytics on health data.
- Real-time streaming from the band.
- Storing raw heart-rate samples or raw usage events.

## Acceptance criteria

- Re-running any import or sync step with the same input leaves the stored
  data unchanged (tested).
- Revoking a Health Connect permission or usage access stops that collection on
  the next run and marks the input as missing with reason `no_consent`.
- No stored table contains package names, window titles, URLs, file names,
  message contents, or keystrokes (checked by the core privacy guard and code
  review).
- Every stored event has a UTC instant, an IANA time zone, and an offset.
