# 0007. Android offline-first storage and background work

- Status: Partly superseded by [0009](0009-flutter-mobile-app.md): Drift replaces Room, and SQLCipher and WorkManager are reached from Flutter. The offline-first rules, encryption, backup exclusion, worker idempotency, and conflict rules still apply.
- Date: 2026-11-27
- Builds on: [0004](0004-offline-first-idempotent-sync.md), which defines sync operations and idempotency

## Context

Every MVP feature except sync must work without a network. Users with ADHD
need logging to be instant and reliable; a lost check-in or a spinner on save
breaks trust. Wearable and screen data arrive in the background.

## Decision

- **Source of truth:** the on-device Room (SQLite) database. The UI reads only
  from it. The server is a backup and sync target, never required for a read.
- **Writes:** every user change is written to its table and to the `outbox`
  table in one Room transaction, as a `SyncOperation` with a client-generated
  UUID operation ID and entity ID ([0004](0004-offline-first-idempotent-sync.md)).
  The outbox is filled only while sync is on.
- **Encryption at rest:** the database is encrypted with SQLCipher for Android.
  A random passphrase is generated on first launch, wrapped with an AES key held
  in Android Keystore, and stored in app-private storage.
- **Backups:** the database and key files are excluded from Android cloud
  backup and device-to-device transfer through backup and data-extraction rules.
- **Background work** (WorkManager, unique named work, `KEEP` policy):

  | Worker | Schedule | Constraints |
  | --- | --- | --- |
  | Health Connect import | Every hour, plus on app open | Battery not low |
  | Screen-use aggregation | Every 3 hours, plus on app open | None |
  | Sync upload and download | When the outbox changes, and every 6 hours | Network connected; only if sync is on |

  Failures retry with exponential backoff. Workers are idempotent, so a retry
  or a duplicate run has no extra effect.
- **Conflicts:** the MVP supports one active device per account. The server
  rejects an operation whose `baseVersion` is stale; the client then downloads
  the current entity and keeps the change with the newer `updated_at`, and
  deletes win over edits. Multi-device conflict handling gets its own decision
  note later.
- **Schema changes:** Room migrations are written and tested for every version
  change; destructive migrations are not allowed.

## Dependencies

| Dependency | Why it is required |
| --- | --- |
| SQLCipher for Android (`net.zetetic:sqlcipher-android`) | Room has no built-in encryption; health data must be encrypted at rest beyond the OS default. |

Room and WorkManager are justified in [0005](0005-android-first-native-kotlin.md).

## Consequences

- The app is fully usable in airplane mode; sync catches up later.
- Encryption adds a small performance cost and a native library to the APK.
- Losing the phone without sync means losing the data; onboarding states this
  and offers export and opt-in sync.

## Acceptance criteria

- With the network disabled, every MVP feature except sync works, and saving a
  check-in never waits on the network (instrumented test).
- Killing the app between the entity write and the outbox write cannot leave one
  without the other (transaction test).
- Running each worker twice in a row changes nothing the second time (test).
- The database file cannot be opened without the Keystore-wrapped passphrase
  (test).
