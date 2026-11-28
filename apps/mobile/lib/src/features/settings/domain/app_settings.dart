import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

enum ThemePreference { system, light, dark }

/// `system` follows the phone's language when it is Polish or English.
enum LanguagePreference { system, en, pl }

/// Preferences and first-start progress stored on the phone.
@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(ThemePreference.system) ThemePreference theme,
    @Default(LanguagePreference.system) LanguagePreference language,
    DateTime? onboardingCompletedAt,
  }) = _AppSettings;

  bool get onboardingCompleted => onboardingCompletedAt != null;
}
