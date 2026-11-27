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
