import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../features/settings/domain/app_settings.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class FlowWaveApp extends ConsumerStatefulWidget {
  const FlowWaveApp({super.key});

  @override
  ConsumerState<FlowWaveApp> createState() => _FlowWaveAppState();
}

class _FlowWaveAppState extends ConsumerState<FlowWaveApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (ref.read(onboardingCompletedProvider) != null) {
          ref.read(syncSchedulerProvider).onAppResumed();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final started = ref.watch(onboardingCompletedProvider) != null;
    final settings = started
        ? ref.watch(settingsProvider).value ?? const AppSettings()
        : const AppSettings();
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeModeFor(settings.theme),
      locale: localeFor(settings.language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // From material_ui, which also adds the widgets and Cupertino
        // delegates; the SDK's flutter_localizations copy targets the
        // built-in Material library.
        ...GlobalMaterialLocalizations.delegates,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
