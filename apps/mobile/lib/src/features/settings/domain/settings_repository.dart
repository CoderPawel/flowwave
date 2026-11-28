import 'app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watch();

  Future<AppSettings> load();

  Future<void> setTheme(ThemePreference theme);

  Future<void> setLanguage(LanguagePreference language);

  Future<void> completeOnboarding(DateTime at);
}
