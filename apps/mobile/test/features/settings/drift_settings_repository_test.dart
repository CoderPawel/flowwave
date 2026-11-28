import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flowwave_mobile/src/features/settings/data/drift_settings_repository.dart';
import 'package:flowwave_mobile/src/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repository;

  setUp(() {
    db = inMemoryDatabase();
    repository = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  test('starts with system theme and language and onboarding to do', () async {
    final settings = await repository.load();
    expect(settings, const AppSettings());
    expect(settings.onboardingCompleted, isFalse);
  });

  test('saves theme, language and onboarding completion', () async {
    await repository.setTheme(ThemePreference.dark);
    await repository.setLanguage(LanguagePreference.pl);
    await repository.completeOnboarding(DateTime.utc(2026, 11, 28, 9));

    expect(
      await repository.load(),
      AppSettings(
        theme: ThemePreference.dark,
        language: LanguagePreference.pl,
        onboardingCompletedAt: DateTime.utc(2026, 11, 28, 9),
      ),
    );
  });

  test('watching emits each change once', () async {
    final seen = <ThemePreference>[];
    final subscription = repository.watch().listen((s) => seen.add(s.theme));
    await pumpEventQueue();
    await repository.setTheme(ThemePreference.light);
    await pumpEventQueue();
    await repository.setTheme(ThemePreference.light);
    await pumpEventQueue();
    await subscription.cancel();
    expect(seen, [ThemePreference.system, ThemePreference.light]);
  });

  test('an unknown stored value falls back to the default', () async {
    await db.customStatement(
      "UPDATE local_settings SET theme_preference = 'sepia'",
    );
    expect((await repository.load()).theme, ThemePreference.system);
  });
}
