# 0005. Android first, with a native Kotlin app

- Status: Superseded by [0009](0009-flutter-mobile-app.md) (Flutter). "Android first" remains accepted.
- Date: 2026-11-27

## Context

The owner and first users are on Android. The MVP depends on Android platform
features: Health Connect, `UsageStatsManager`, WorkManager background jobs,
notification actions for one-tap check-ins, and a home-screen widget.
iOS, a web panel, and a Windows agent come later.

The roadmap earlier proposed React Native with Expo so the TypeScript core could
run on the phone. With the data sources now fixed, most MVP work sits in native
Android APIs, so the choice was re-evaluated.

## Options

| Option | For | Against |
| --- | --- | --- |
| Native Kotlin (Jetpack Compose, Room, WorkManager, Health Connect client) | First-class access to every API the MVP needs; reliable background work; native widgets and notification actions; official Health Connect samples | Domain rules from `@flowwave/core` must be mirrored in Kotlin; iOS later needs separate UI work |
| React Native with Expo | Reuses `@flowwave/core` directly; one codebase for iOS later | Health Connect via a community library; usage stats, widgets, and notification actions need custom native modules anyway; background JavaScript is less reliable |
| Flutter | One codebase for iOS later | Same native-module burden as React Native; no core reuse; another language |
| Kotlin Multiplatform | Shares domain logic with iOS later | More setup now; benefits only once iOS starts |

## Decision (proposed)

- Build the Android app natively in Kotlin with Jetpack Compose, Room,
  WorkManager, and the Health Connect Jetpack client.
- `minSdk 28` (Android 9), the oldest version Health Connect supports and the
  first that reports screen-interactive usage events. `targetSdk` follows the
  current Google Play requirement.
- Keep `@flowwave/core` as the reference implementation of the domain rules.
  Add shared JSON test vectors (inputs and expected outputs for time handling,
  missing data, consent, privacy guard, operation fingerprints, and estimates)
  under `packages/core/test/vectors/`. The TypeScript and Kotlin test suites
  both run them, so the two implementations cannot drift silently.
- Revisit Kotlin Multiplatform when iOS work starts, so domain logic can be
  shared with iOS from Kotlin.

## Dependencies (added in phase 1)

| Dependency | Why it is required |
| --- | --- |
| Kotlin and Android Gradle Plugin | Language and build system for Android. |
| Jetpack Compose | Standard Android UI toolkit; needed for the app and widget UI (Glance). |
| Room | Typed SQLite access with migrations for the on-device database ([0007](0007-android-offline-first-storage.md)). |
| WorkManager | Reliable, battery-aware background jobs for imports and sync. |
| `androidx.health.connect:connect-client` | Only supported way to read Health Connect ([0006](0006-health-connect-wearable-gateway.md)). |

Each further dependency is justified in the phase that adds it.

## Consequences

- Phase 1 sets up `apps/android` with a Gradle build and its own CI job.
- Domain rules exist twice; the shared test vectors are mandatory for every
  rule change.
- If the owner prefers a single codebase for a near-term iOS release, this note
  is superseded by one choosing React Native or Kotlin Multiplatform.

## Acceptance criteria

- The owner confirms the UI stack, and this note's status becomes Accepted.
- Phase 1 CI builds the Android app and runs both TypeScript and Kotlin tests
  against the same vectors.
