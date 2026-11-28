# FlowWave mobile (Flutter)

Offline-first Android app. See [decision 0009](../../docs/architecture/0009-flutter-mobile-app.md)
for the libraries, [decision 0015](../../docs/architecture/0015-flutter-app-architecture.md)
for how the app is put together, and the [roadmap](../../docs/roadmap.md) for
what is built in which step.

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run            # on a connected Android device or emulator
flutter build apk --debug
```

`minSdk` is 28 (Android 9) because Health Connect and the screen-session
events used in later steps require it. Android auto-backup is disabled so
locally stored rhythm data never leaves the device without an explicit sync.

## Structure

```text
lib/
  main.dart                    runs the app inside a Riverpod ProviderScope
  l10n/                        app_en.arb, app_pl.arb; generated/ is gen-l10n output
  src/
    app/                       MaterialApp, go_router routes, theme, tab shell,
                               providers.dart (the composition root)
    core/                      config, database, errors, network, sync, time
    features/<feature>/
      domain/                  models and repository interfaces
      data/                    Drift and Dio implementations
      presentation/            screens and widgets
```

Features: `startup`, `auth`, `privacy`, `consent`, `onboarding`, `today`,
`check_in`, `timeline`, `insights` (the last four are placeholders), and
`settings`. Screens read data through repository interfaces; tests override
the providers in `lib/src/app/providers.dart`.

## Generated code

Drift tables, Freezed models, JSON serialization and localizations are
generated and committed. After changing them:

```bash
dart run build_runner build
flutter gen-l10n
dart format lib test
dart run drift_dev schema dump lib/src/core/database/app_database.dart drift_schemas/
```

CI runs the same commands and fails if anything changes. A new database
schema version needs a migration in `AppDatabase.migration`, a new schema dump
in `drift_schemas/`, and a row per new column in the
[data inventory](../../docs/privacy/data-inventory.md#on-the-phone)
(`test/core/database/data_inventory_test.dart` checks it).

## Local database

- Drift on SQLite is the source of truth; screens never wait for the network.
- The `sqlite3` build hook bundles SQLite3MultipleCiphers (`hooks:` in
  `pubspec.yaml`). A random 256-bit key is created on first start and kept in
  `flutter_secure_storage`. The app refuses to open the database if the
  cipher is not active.
- If the key no longer matches the file, the startup screen explains that the
  local data cannot be read and offers to reset it. Nothing is deleted
  without that confirmation.

## Accounts and sync

The app works fully without an account; nothing leaves the phone until the
user signs in ([decision 0013](../../docs/architecture/0013-authentication-and-sessions.md)).

- `SecureTokenStore` keeps tokens in `flutter_secure_storage` (Android
  Keystore; iOS Keychain, this device only), never in preferences or files.
- `AuthSession` refreshes the access token 60 seconds before it expires, with
  one refresh at a time, and signs out locally when the server ends the
  session.
- `AuthInterceptor` adds the token to API requests (Dio) and retries once
  after a `401`.
- `LogoutCleanup` runs every registered deletion task at sign-out, also
  offline. Features that store account data on the phone must register one
  in `providers.dart`.
- While signed in, every change is also written to `outbox_operations` in the
  same transaction. `SyncService` uploads them oldest first; the operation ID
  is the record ID, so a repeated upload is a no-op on the server. Network
  errors, `5xx` and `429` retry with backoff up to one hour; refused changes
  stay visible on the data and privacy screen.
- All errors become an `AppFailure` (`core/errors`), and screens show a
  localized message for each case.

The API address is set at build time; without it the app runs offline and
never signs in:

```bash
flutter run --dart-define=FLOWWAVE_API_BASE_URL=http://10.0.2.2:3000/
```

Debug builds may use plain HTTP to `10.0.2.2` and `localhost` only
(`android/app/src/debug/res/xml/network_security_config.xml`); release builds
use HTTPS only.

## Localization and accessibility

English and Polish (`lib/l10n/*.arb`). The phone's language is used unless
the user picks one in Settings. Every icon-only control has a tooltip or
semantics label; `test/widget/accessibility_test.dart` checks Android tap
target size, labels, and text contrast on each screen.

## Tests

- `test/core`, `test/features/*`: repositories against an in-memory Drift
  database, the sync service, error mapping, the encrypted database (a real
  SQLite3MultipleCiphers file), and the consent rules against the shared
  vectors in `packages/core/test-vectors`.
- `test/widget`: the app with a fake server (`test/support/test_app.dart`):
  first start, sign-in and registration, settings, data and privacy, startup
  failures, and accessibility.
