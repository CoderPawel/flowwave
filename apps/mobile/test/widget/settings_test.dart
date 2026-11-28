import 'package:flowwave_mobile/src/app/providers.dart';
import 'package:flowwave_mobile/src/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_http_adapter.dart';
import '../support/test_app.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester);
}

void main() {
  testWidgets('the theme choice applies at once and is saved', (tester) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);
    await _openSettings(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    await tester.tap(find.text('Dark'));
    await settle(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Settings'))).brightness,
      Brightness.dark,
    );
    expect(
      (await app.container.read(settingsRepositoryProvider).load()).theme,
      ThemePreference.dark,
    );
  });

  testWidgets('switching to Polish translates the app', (tester) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);
    await _openSettings(tester);

    await tester.tap(find.text('Polski'));
    await settle(tester);

    expect(find.text('Ustawienia'), findsOneWidget);
    expect(find.text('Motyw'), findsOneWidget);
    expect(find.text('Dane i prywatność'), findsOneWidget);
  });

  testWidgets('a Polish phone gets Polish without choosing', (tester) async {
    final app = TestApp();
    await app.pump(tester, locale: const Locale('pl', 'PL'));
    expect(find.text('Twoje dane należą do Ciebie'), findsOneWidget);
  });

  testWidgets('an unsupported phone language falls back to English', (
    tester,
  ) async {
    final app = TestApp();
    await app.pump(tester, locale: const Locale('de', 'DE'));
    expect(find.text('Your data stays yours'), findsOneWidget);
  });

  testWidgets('signing out warns about changes not uploaded yet', (
    tester,
  ) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.signIn();
    app.server.handler = (request) => const FakeResponse(503);
    await app.pump(tester);
    await _openSettings(tester);
    final repository = app.container.read(consentRepositoryProvider);

    await tapInList(tester, find.text('Data and privacy'));
    await tester.tap(find.byKey(const ValueKey('consent-notifications')));
    await settle(tester);
    expect(await repository.log(), hasLength(1));
    await tester.pageBack();
    await settle(tester);

    await tapInList(tester, find.text('Sign out'));
    expect(
      find.textContaining(
        '1 change has not been uploaded yet and will be lost.',
      ),
      findsOneWidget,
      reason: 'the server is down, so the decision is still queued',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await settle(tester);

    expect(app.tokens.tokens, isNull);
    expect(await repository.log(), isEmpty, reason: 'account data removed');
    expect(find.byType(SnackBar), findsNothing, reason: 'cleanup succeeded');
    expect(find.textContaining('Not signed in.'), findsOneWidget);
    expect(
      (await app.container.read(settingsRepositoryProvider).load())
          .onboardingCompleted,
      isTrue,
      reason: 'preferences stay',
    );
  });
}
