# 0014. Consent types, data export, and account deletion

- Status: Accepted
- Date: 2026-11-28
- Implements: roadmap step 4 ([prompt 4](../prompts/prompt-04-auth-privacy.md)); extends [0003](0003-privacy-and-consent.md); changes the export endpoint listed in [0008](0008-nestjs-sync-api.md)

## Context

Consent (0003) covers external sources only: one append-only decision per
source with scopes and a policy version. Prompt 4 asks for separate consent
for health data, device usage, notifications and analytics, each with a
version, a timestamp and withdrawal, plus an account data export job and an
account deletion workflow. Decision 0012 left purging old tombstones to this
step.

## Decision

### Consent types

`consent_decisions` gains a `consent_type`:

| Type | Subject | Scopes | Policy version |
| --- | --- | --- | --- |
| `health_data` | One external health source (`health_connect`, `apple_health`) | Data categories of that source | Own version |
| `device_usage` | Android usage access | None | Own version |
| `notifications` | Reminders and suggestions | None | Own version |
| `analytics` | Product analytics (none exist yet) | None | Own version |

- Existing decisions become `health_data`, so rule 6 (consent per external
  source) still holds.
- Each type has its own policy version
  (`CURRENT_CONSENT_POLICY_VERSIONS` in `@flowwave/core`), so changing the
  analytics text does not invalidate health consent.
- A decision is still immutable and the latest one wins.
- **Grants** must use the current version of their type. Grants under an
  older version stay in the history but do not count as active.
- **Withdrawal** is a `revoked` decision. It is accepted under any version
  and never needs scopes.
- Decisions carry a client-generated ID (offline-first, rule 7). Repeating a
  decision returns the stored one; reusing an ID with different content is a
  `409`.
- The health sources declare three more scopes: `steps`, `heart_rate` and
  `resting_heart_rate`. The import repositories from step 3 now check
  consent per scope before storing a Health Connect or Apple Health record:
  a sample's metric is its scope, and a sleep session needs
  `sleep_duration`. Manual entries need no consent.
- Device usage buckets need `device_usage` consent. Collection itself still
  starts in steps 8 and 9.

**Effects of withdrawal.** A revocation stops collection at once: the server
rejects new records of that type with `403 consent_required`, and the phone
stops reading the source (steps 8 and 9). Data collected before stays, because
the user may want to keep their history, unless the user asks for its
deletion in the same request (`deleteCollectedData: true`):

- for `health_data`: deletes every record from data sources of that kind and
  marks the sources disconnected;
- for `device_usage`: deletes every usage bucket.

`notifications` and `analytics` store no data, so withdrawing them only
stops the feature.

### Data export job

- `POST /v1/account/exports` creates a job, or returns the unfinished one, so
  repeating the request is safe.
- A worker in the API process claims pending jobs with a conditional update,
  so a job runs once even if several workers poll.
- It writes one JSON document with every row the user owns, keyed by table
  and column names from the [data dictionary](../data/data-dictionary.md).
  Password hashes and token hashes are left out: they are secrets, not user
  data.
- The result is kept in `data_export_jobs` (encrypted at rest with the
  database) for 7 days. `GET /v1/account/exports/{id}` shows the status and
  `GET /v1/account/exports/{id}/download` returns the file.
- Requesting and completing an export are audit events.
- This replaces the synchronous `GET /v1/export` sketched in 0008, because an
  export of months of 5-minute heart rate is too large for one request.
- Export of data that exists only on the phone is part of the mobile app
  (step 5 onwards).

### Account deletion

- `DELETE /v1/account` requires the current password again.
- In one transaction it deletes the user row, which cascades to every table
  with a `user_id`: credentials, sessions, tokens and export jobs included.
  It then writes an `account_deleted` audit event without a user ID and
  returns that event's ID as a deletion receipt.
- There is no grace period: keeping health data after the user asked for its
  deletion would contradict the request. The app offers the export first.
- Afterwards the phone runs the full sign-out cleanup.
- Backups age out with the backup retention of the hosting provider, chosen
  before the pilot (step 17).

### Retention

An hourly job in the API process:

- deletes sessions (and their tokens) 30 days after they were revoked or
  expired;
- removes export results after 7 days and export jobs after 30 days;
- hard-deletes tombstones (`deleted_at_utc`) older than 90 days in event and
  record tables. Devices and data sources are kept, because records refer to
  them.

Step 10 (sync) must make a device that was offline for more than 90 days do a
full resync instead of relying on tombstones.

## Consequences

- One more column in every consent query; consent checks name a type.
- Background work runs inside the API process; it can move to a separate
  worker later because jobs are claimed atomically.
- A deleted account cannot be restored.

## Acceptance criteria

- Tests show: each consent type is granted and withdrawn independently;
  grants with an old policy version are rejected; withdrawal makes the
  import repositories refuse new data; `deleteCollectedData` removes only the
  data of that type; consent history stays complete.
- An export contains the user's rows and no other user's rows, no password or
  token hashes, and expires.
- Account deletion requires the password, leaves no row with the user's ID,
  and keeps an audit event without it.
