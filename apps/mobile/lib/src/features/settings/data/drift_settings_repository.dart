import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$LocalSettingsTable, LocalSettingsRow> get _row =>
      _db.select(_db.localSettings)..where((t) => t.id.equals(1));

  @override
  Stream<AppSettings> watch() =>
      _row.watchSingleOrNull().map(_toDomain).distinct();

  @override
  Future<AppSettings> load() async => _toDomain(await _row.getSingleOrNull());

  @override
  Future<void> setTheme(ThemePreference theme) =>
      _write(LocalSettingsCompanion(themePreference: Value(theme.name)));

  @override
  Future<void> setLanguage(LanguagePreference language) =>
      _write(LocalSettingsCompanion(languagePreference: Value(language.name)));

  @override
  Future<void> completeOnboarding(DateTime at) => _write(
    LocalSettingsCompanion(onboardingCompletedAtUtc: Value(at.toUtc())),
  );

  Future<void> _write(LocalSettingsCompanion changes) => _db
      .into(_db.localSettings)
      .insert(
        changes.copyWith(id: const Value(1)),
        onConflict: DoUpdate((_) => changes),
      );

  static AppSettings _toDomain(LocalSettingsRow? row) {
    if (row == null) return const AppSettings();
    return AppSettings(
      theme:
          _byName(ThemePreference.values, row.themePreference) ??
          ThemePreference.system,
      language:
          _byName(LanguagePreference.values, row.languagePreference) ??
          LanguagePreference.system,
      onboardingCompletedAt: row.onboardingCompletedAtUtc?.toUtc(),
    );
  }

  static T? _byName<T extends Enum>(List<T> values, String name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
