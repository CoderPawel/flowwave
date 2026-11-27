# 0009. Flutter mobile app

- Status: Accepted
- Date: 2026-11-27
- Supersedes: [0005](0005-android-first-native-kotlin.md) (UI stack); the Room, SQLCipher-for-Room, and WorkManager-from-Kotlin parts of [0007](0007-android-offline-first-storage.md)

## Context

Decision note 0005 proposed a native Kotlin app and waited for the owner. The
owner's plan (Copilot prompts 2, 5, and 8) chooses Flutter, with small Kotlin
platform channels where Flutter packages lack a capability (Health Connect
gaps, `UsageStatsManager`). Android remains the first and only MVP platform;
Flutter keeps iOS within reach later.

## Decision

- `apps/mobile` is a Flutter application (Dart, Material 3), Android first.
- Libraries chosen by the owner's plan, each with its reason:

  | Library | Why it is required |
  | --- | --- |
  | `flutter_riverpod` | State management and dependency injection for a layered, testable app. |
  | `go_router` | Declarative navigation and deep links (check-in notification links). |
  | `dio` | HTTP client with interceptors for token refresh and error mapping. |
  | `drift` + `sqlite3` | Typed SQLite with migrations; the on-device source of truth (offline first). |
  | `freezed`, `json_serializable` | Immutable domain models and JSON mapping without hand-written boilerplate. |
  | `flutter_secure_storage` | Tokens and the database key in Android Keystore-backed storage. |

  Packages are added in the phase that first needs them, not all at once.
- Offline-first rules from [0004](0004-offline-first-idempotent-sync.md) and
  [0007](0007-android-offline-first-storage.md) still apply: the local
  database is the source of truth, every write goes to its table and the outbox
  in one transaction, workers are idempotent, the database is encrypted, and
  it is excluded from Android backup.
- Database encryption uses SQLCipher through Drift's supported SQLCipher setup;
  the key is stored with `flutter_secure_storage`. Chosen in the Drift phase.
- Background work uses Android WorkManager, through a Flutter plugin or a
  Kotlin platform channel, chosen in the Health Connect phase.
- Domain rules that the app must apply offline (time handling, missing data,
  privacy guard, operation fingerprints) are implemented in Dart and checked
  against shared JSON test vectors from `packages/core`, as 0005 required for
  Kotlin.

## Consequences

- One mobile codebase that can later target iOS.
- Platform channels in Kotlin are needed for `UsageStatsManager` and possibly
  some Health Connect features; they stay minimal and tested.
- CI needs a Flutter job (`flutter analyze`, `flutter test`).

## Acceptance criteria

- `flutter analyze` and `flutter test` run in CI.
- The app builds for Android with `minSdk 28` once Health Connect is added.
