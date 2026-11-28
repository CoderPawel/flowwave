import 'package:flowwave_mobile/src/app/providers.dart';
import 'package:flowwave_mobile/src/core/database/encrypted_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/fake_http_adapter.dart';
import '../support/test_app.dart';

Future<void> _openDataPrivacy(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await settle(tester);
  await tester.tap(find.text('Data and privacy'));
  await settle(tester);
}

void main() {
  testWidgets('signed out: sync is off and consents can be changed', (
    tester,
  ) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);
    await _openDataPrivacy(tester);

    expect(find.text('No consent decisions stored'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('consent-notifications')));
    await settle(tester);
    expect(find.text('1 consent decision stored'), findsOneWidget);

    await tester.scrollUntilVisible(find.textContaining('Sync is off'), 100);
    expect(find.textContaining('Sync is off'), findsOneWidget);
    expect(find.text('Delete account'), findsNothing);
  });

  testWidgets('signed in: shows queued and refused changes; sync now', (
    tester,
  ) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.signIn();
    var serverUp = false;
    app.server.handler = (request) {
      if (!serverUp) return const FakeResponse(503);
      return request.path == '/v1/consents/history'
          ? FakeResponse.json([])
          : FakeResponse.json({'replayed': false}, status: 201);
    };
    await app.pump(tester);
    await _openDataPrivacy(tester);

    await tester.tap(find.byKey(const ValueKey('consent-notifications')));
    await settle(tester);
    await tester.scrollUntilVisible(find.text('Sync now'), 200);
    expect(find.text('1 change is waiting to upload.'), findsOneWidget);

    serverUp = true;
    await tapInList(tester, find.text('Sync now'));

    expect(find.text('Everything is uploaded.'), findsOneWidget);
    expect(find.text('Sync finished.'), findsOneWidget);
  });

  testWidgets('deleting data on this phone returns to the welcome flow', (
    tester,
  ) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);
    await _openDataPrivacy(tester);
    await tester.tap(find.byKey(const ValueKey('consent-notifications')));
    await settle(tester);

    await tapInList(tester, find.text('Delete data on this phone'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(find.text('Your data stays yours'), findsOneWidget);
    expect(await app.container.read(consentRepositoryProvider).log(), isEmpty);
  });

  testWidgets('deleting the account asks for the password', (tester) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.signIn();
    String? sentPassword;
    app.server.handler = (request) {
      if (request.method == 'DELETE' && request.path == '/v1/account') {
        sentPassword =
            (request.body! as Map<String, Object?>)['password'] as String?;
        if (sentPassword != 'correct horse battery staple') {
          return FakeResponse.json({
            'statusCode': 403,
            'error': 'authentication_failed',
            'message': 'Password is incorrect.',
            'reason': 'reauthentication_failed',
          }, status: 403);
        }
        return FakeResponse.json({
          'receiptId': 'r1',
          'deletedAt': '2026-11-28T09:00:00.000Z',
        });
      }
      return FakeResponse.json([]);
    };
    await app.pump(tester);
    await _openDataPrivacy(tester);

    await tapInList(tester, find.text('Delete account'));
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)),
      'wrong password',
    );
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'Delete account'),
      ),
    );
    await settle(tester);
    expect(find.text('The password is incorrect.'), findsOneWidget);
    expect(app.tokens.tokens, isNotNull);

    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)),
      'correct horse battery staple',
    );
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'Delete account'),
      ),
    );
    await settle(tester);

    expect(find.text('Your account was deleted.'), findsOneWidget);
    expect(app.tokens.tokens, isNull);
    expect(
      app.server.paths.where((p) => p == '/v1/auth/logout'),
      isEmpty,
      reason: 'the deleted account has no session to end',
    );
  });

  group('startup', () {
    testWidgets('a lost database key explains the loss and offers a reset', (
      tester,
    ) async {
      var attempts = 0;
      late TestApp app;
      app = TestApp(
        opener: () async {
          attempts += 1;
          if (app.resets == 0) throw const DatabaseKeyMismatchException();
          return app.db;
        },
      );
      await app.pump(tester);

      expect(find.text('Data on this phone cannot be read'), findsOneWidget);
      expect(attempts, 1, reason: 'never retried silently');

      await tester.tap(find.text('Reset data on this phone'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(app.resets, 1);
      expect(find.text('Your data stays yours'), findsOneWidget);
    });

    testWidgets('other failures offer a retry', (tester) async {
      var fail = true;
      late TestApp app;
      app = TestApp(
        opener: () async {
          if (fail) throw StateError('disk');
          return app.db;
        },
      );
      await app.pump(tester);
      expect(find.text('FlowWave could not start'), findsOneWidget);

      fail = false;
      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(find.text('Your data stays yours'), findsOneWidget);
      expect(app.resets, 0);
    });

    testWidgets('missing encryption is never worked around', (tester) async {
      final app = TestApp(
        opener: () async => throw const EncryptionUnavailableException(),
      );
      await app.pump(tester);
      expect(
        find.textContaining('never stores data unencrypted'),
        findsOneWidget,
      );
      expect(find.text('Reset data on this phone'), findsNothing);
    });
  });
}
