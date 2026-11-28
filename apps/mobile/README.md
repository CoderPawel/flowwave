# FlowWave mobile (Flutter)

Offline-first Android app. See [decision 0009](../../docs/architecture/0009-flutter-mobile-app.md)
and the [roadmap](../../docs/roadmap.md) for what is built in which step.

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

## Authentication

`lib/src/auth` signs in to the FlowWave API
([decision 0013](../../docs/architecture/0013-authentication-and-sessions.md)):

- `SecureTokenStore` keeps tokens in `flutter_secure_storage` (Android
  Keystore; iOS Keychain, this device only), never in preferences or files.
- `AuthSession` refreshes the access token 60 seconds before it expires, with
  one refresh at a time, and signs out locally when the server ends the
  session.
- `AuthenticatedClient` adds the token to API requests and retries once after
  a `401`.
- `LogoutCleanup` runs every registered deletion task at sign-out, also
  offline. Features that store account data on the phone must register one.

The API address is set at build time; without it the app runs offline and
never signs in:

```bash
flutter run --dart-define=FLOWWAVE_API_BASE_URL=http://10.0.2.2:3000/
```

Debug builds may use plain HTTP to `10.0.2.2` and `localhost` only
(`android/app/src/debug/res/xml/network_security_config.xml`); release builds
use HTTPS only.
