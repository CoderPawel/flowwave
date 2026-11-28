# 0015. Flutter app architecture

- Status: Accepted
- Date: 2026-11-28
- Implements: roadmap step 5 ([prompt 5](../prompts/prompt-05-flutter-foundation.md)); builds on [0009](0009-flutter-mobile-app.md), [0007](0007-android-offline-first-storage.md) and [0013](0013-authentication-and-sessions.md)

## Context

Step 5 turns the placeholder app into the foundation later steps build on:
navigation, local storage, an offline write queue with synchronization,
localization, theming, and the first screens (startup, sign-in, privacy,
consent, onboarding, settings, data and privacy, and placeholders for the
main tabs). Decision 0009 chose the libraries; this note fixes how they fit
together and settles what 0009 left to "the Drift phase".

## Decision

### Layout

Feature first, with layers inside each feature:

```text
lib/
  main.dart                 bootstrap: open storage, restore session, run app
  l10n/                     ARB files (en, pl) and generated localizations
  src/
    app/                    MaterialApp, router, theme, shell with tabs
    core/                   database, network, errors, sync, time, config
    features/<feature>/
      domain/               models (Freezed) and repository interfaces
      data/                 repository implementations (Drift, Dio)
      presentation/         screens, widgets, Riverpod controllers
```

Presentation depends on domain only; data implements domain interfaces;
Riverpod providers wire them and are overridden in tests.

### Accounts are optional

The app works fully without an account (rule 8). Signing in turns sync on
([data flow](data-flow.md)). First start: startup → privacy introduction →
consent selection → onboarding → Today. Onboarding ends with "create
account", "sign in", or "continue without account"; both sign-in screens are
also reachable from Settings.

### Local database

- Drift on SQLite is the source of truth; the UI reads from it only.
- **Encryption:** `package:sqlite3` bundles SQLite3MultipleCiphers (hook
  option `source: sqlite3mc`, ChaCha20-Poly1305) instead of SQLCipher. This
  refines 0009: both are maintained encrypted SQLite builds distributed by the
  same package, but SQLite3MultipleCiphers needs no OpenSSL in the APK and is
  MIT licensed. A random 256-bit key is created on first start and kept in
  `flutter_secure_storage`. Opening the database fails, instead of silently
  falling back to an unencrypted file, when the cipher is not active.
- If the key is lost (for example after the user clears app storage
  partially) the database cannot be read. The startup screen says so and
  offers to reset local data; nothing is deleted without that confirmation.
- Tables in schema version 1: `local_settings` (one row: theme, language,
  onboarding state), `consent_decisions` (local copy of the user's decisions
  with sync state), `outbox_operations` (the write queue).
- Android backup stays disabled, so neither the database nor the key leaves
  the phone ([0007](0007-android-offline-first-storage.md)).

### Offline-first write queue and synchronization

- As 0007 requires, a change is written to its table and, while sync is on
  (signed in), to `outbox_operations` in the same transaction. The operation
  ID is the entity ID, so enqueuing the same change twice is a no-op.
- When sync turns on, entities not yet uploaded are enqueued.
- `SyncService` sends operations oldest first through one transport per kind.
  Step 5 has one kind, `consent_decision`, sent to the idempotent
  `POST /v1/consents`; step 10 adds the generic sync endpoint.
- Outcomes: success marks the entity synced and removes the operation;
  network errors, `5xx` and `429` retry with exponential backoff (up to one
  hour); `401` pauses the queue until the user signs in again; `400`, `403`,
  `404`, `409` and `422` mark the operation rejected. Rejected operations stay
  visible on the data and privacy screen and are never retried silently.
- Sync runs after each enqueue, at startup, after sign-in, and when the app
  returns to the foreground. Background sync (WorkManager) comes with step 10.
- Signing out deletes the queue together with all other account data. The
  sign-out dialog says how many changes have not been uploaded yet.

### Network and errors

- Dio replaces `package:http` in the authentication module from step 4, so
  the app has one HTTP stack with interceptors (0009). Behavior is unchanged:
  single-flight refresh 60 seconds before expiry, one retry after `401`,
  local sign-out when the server ends the session.
- All failures become one sealed `AppFailure` type (network, session ended,
  validation with field, conflict, consent required, rate limited with retry
  time, not found, server, storage, unknown), mapped in one place from Dio
  errors and the API error body (`error`, `reason`, `field`). Screens show a
  localized message for each case and never show raw server messages.

### Time

Timestamps are created with the device's IANA time zone (from
`flutter_timezone`) and the offset at that instant, truncated to milliseconds
because the API accepts at most three fractional digits (rule 9).

### Consent selection

- The four consent types from 0014, all off by default (opt in). Health data
  lists the Health Connect scopes; the screen says that nothing is read until
  a later version adds the import, and Health Connect itself is not added
  (prompt 5).
- Consent text versions are duplicated in Dart; an API test fails when they
  differ from `@flowwave/core`.

### Localization, theme, accessibility

- Polish and English through `gen-l10n` ARB files; the system language is
  used unless the user picks one in Settings.
- Material 3 light and dark themes from one seed color; the user can choose
  system, light, or dark.
- Every icon-only control and status indicator has a semantics label; widget
  tests check the labels of key controls.

### Generated code

Drift, Freezed, JSON and localization code is generated and committed, so a
clean checkout analyzes and tests without a build step. CI regenerates it and
fails if the result differs.

## Dependencies

| Dependency | Why it is required |
| --- | --- |
| `flutter_riverpod`, `go_router`, `dio`, `drift`, `freezed_annotation`, `json_annotation` | Chosen in [0009](0009-flutter-mobile-app.md); added now because step 5 first needs them. |
| `drift_flutter` | Opens the Drift database in a background isolate at the app documents path; maintained with Drift. |
| `flutter_localizations`, `intl` | Flutter's localization support for Polish and English (part of the SDK and its standard companion). |
| `flutter_timezone` | Flutter exposes only time zone abbreviations ("CET"); rule 9 needs the IANA name. |
| `build_runner`, `drift_dev`, `freezed`, `json_serializable` (dev only) | Code generators for the libraries above. |
| `package:http` | Removed; replaced by Dio. |

## Consequences

- Later features add a table, a repository interface, and an outbox kind
  instead of new infrastructure.
- Generated files make pull requests larger; the CI check keeps them honest.
- A lost database key means losing local data that was never synced; the
  startup screen explains this, and onboarding offers an account for backup.

## Acceptance criteria

- `flutter analyze` and `flutter test` pass in CI, and regenerated code
  matches the committed code.
- Repository tests show: consent decisions and their outbox operations are
  written in one transaction; enqueuing twice keeps one operation; sync
  removes sent operations, retries network failures with backoff, pauses on
  `401`, and keeps rejected operations; sign-out cleanup empties account
  tables; the database cannot be opened with a wrong key.
- Widget tests cover the first-start flow, sign-in errors, consent selection,
  settings (theme and language), the data and privacy screen, and semantics
  labels.
