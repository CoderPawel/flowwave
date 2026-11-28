import 'dart:async';
import 'dart:io';

import 'package:flowwave_mobile/src/app/providers.dart';
import 'package:flowwave_mobile/src/app/routes.dart';
import 'package:flowwave_mobile/src/app/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/auth_fakes.dart';
import '../support/fake_http_adapter.dart';
import '../support/test_app.dart';

Future<void> _openFromOnboarding(
  WidgetTester tester,
  TestApp app,
  String location,
) async {
  await app.pump(tester);
  app.container.read(routerProvider).go(Routes.onboarding);
  await tester.pumpAndSettle();
  unawaited(app.container.read(routerProvider).push(location));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('sign-in', () {
    testWidgets('checks the form before calling the API', (tester) async {
      final app = TestApp();
      await _openFromOnboarding(tester, app, Routes.welcomeLogin);

      await tester.enterText(_field('Email'), 'not-an-email');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(app.server.requests, isEmpty);
    });

    testWidgets('shows a wrong password without the server message', (
      tester,
    ) async {
      final app = TestApp();
      app.server.handler = (request) => unauthorized('invalid_credentials');
      await _openFromOnboarding(tester, app, Routes.welcomeLogin);

      await tester.enterText(_field('Email'), 'tester@example.org');
      await tester.enterText(_field('Password'), 'wrong password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
      expect(find.text('Authentication failed.'), findsNothing);
      expect(app.tokens.tokens, isNull);
    });

    testWidgets('offline: explains that local data is safe', (tester) async {
      final app = TestApp();
      app.server.handler = (request) => throw const SocketException('offline');
      await _openFromOnboarding(tester, app, Routes.welcomeLogin);

      await tester.enterText(_field('Email'), 'tester@example.org');
      await tester.enterText(_field('Password'), 'long password 1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No connection'), findsOneWidget);
    });

    testWidgets('success from onboarding signs in, completes onboarding and '
        'uploads consent given before', (tester) async {
      final app = TestApp();
      final uploaded = <Object?>[];
      app.server.handler = (request) {
        switch (request.path) {
          case '/v1/auth/login':
            return tokenResponse(tokensFor(1, app.clock.current));
          case '/v1/consents/history':
            return FakeResponse.json([]);
          case '/v1/consents':
            uploaded.add(request.body);
            return FakeResponse.json({'replayed': false}, status: 201);
        }
        return const FakeResponse(404);
      };
      await app.pump(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('consent-notifications')));
      await tester.pumpAndSettle();
      app.container.read(routerProvider).go(Routes.onboarding);
      await tester.pumpAndSettle();
      unawaited(app.container.read(routerProvider).push(Routes.welcomeLogin));
      await tester.pumpAndSettle();

      await tester.enterText(_field('Email'), ' Tester@Example.org ');
      await tester.enterText(_field('Password'), 'long password 1');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      // Sync runs in the background; let its requests finish.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(app.tokens.tokens, isNotNull);
      final login = app.server.requests.firstWhere(
        (r) => r.path == '/v1/auth/login',
      );
      expect(
        (login.body! as Map<String, Object?>)['email'],
        'Tester@Example.org',
        reason: 'trimmed; the server normalizes case',
      );
      expect(app.server.paths, contains('/v1/consents/history'));
      expect(uploaded, hasLength(1));
      expect(
        (uploaded.single! as Map<String, Object?>)['type'],
        'notifications',
      );
      expect(
        await app.container.read(consentRepositoryProvider).log(),
        hasLength(1),
      );
    });
  });

  group('registration', () {
    testWidgets('requires 12 to 128 characters and a matching repeat', (
      tester,
    ) async {
      final app = TestApp();
      await _openFromOnboarding(tester, app, Routes.welcomeRegister);

      await tester.enterText(_field('Email'), 'tester@example.org');
      await tester.enterText(_field('Password'), 'short');
      await tester.enterText(_field('Repeat password'), 'other');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Use 12 to 128 characters.'), findsOneWidget);
      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(app.server.requests, isEmpty);
    });

    testWidgets('sends the device time zone and reports a taken email', (
      tester,
    ) async {
      final app = TestApp();
      app.server.handler = (request) => FakeResponse.json({
        'statusCode': 409,
        'error': 'conflict',
        'message': 'An account with this email already exists.',
        'field': 'email',
      }, status: 409);
      await _openFromOnboarding(tester, app, Routes.welcomeRegister);

      expect(find.textContaining('(Europe/Warsaw)'), findsOneWidget);
      await tester.enterText(_field('Email'), 'tester@example.org');
      await tester.enterText(_field('Password'), 'long password 1');
      await tester.enterText(_field('Repeat password'), 'long password 1');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Create account'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      final body = app.server.requests.single.body! as Map<String, Object?>;
      expect(body['homeTimeZone'], 'Europe/Warsaw');
      expect(
        find.text('An account with this email already exists.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('sign-in from settings returns to settings', (tester) async {
    final app = TestApp();
    app.server.handler = (request) => request.path == '/v1/auth/login'
        ? tokenResponse(tokensFor(1, app.clock.current))
        : FakeResponse.json([]);
    await app.completeOnboarding();
    await app.pump(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Email'), 'tester@example.org');
    await tester.enterText(_field('Password'), 'long password 1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('Signed in.'), findsOneWidget);
    expect(app.container.read(isSignedInProvider), isTrue);
  });
}
