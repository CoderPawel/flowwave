import 'package:material_ui/material_ui.dart';

import '../features/settings/domain/app_settings.dart';

const Color _seed = Color(0xFF2F6F8F);

/// Material 3 theme from the FlowWave seed color.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    // Large touch targets help everyone, including people with motor
    // difficulties.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeMode themeModeFor(ThemePreference preference) => switch (preference) {
  ThemePreference.system => ThemeMode.system,
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
};

/// `null` follows the phone's language.
Locale? localeFor(LanguagePreference preference) => switch (preference) {
  LanguagePreference.system => null,
  LanguagePreference.en => const Locale('en'),
  LanguagePreference.pl => const Locale('pl'),
};
