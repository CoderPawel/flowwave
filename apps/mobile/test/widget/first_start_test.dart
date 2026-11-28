import 'package:flowwave_mobile/src/app/providers.dart';
import 'package:flowwave_mobile/src/core/sync/outbox_operation.dart';
import 'package:flowwave_mobile/src/features/consent/domain/consent_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

void main() {
  testWidgets(
    'first start: privacy, consent, onboarding, then Today without account',
    (tester) async {
      final app = TestApp();
      await app.pump(tester);

      expect(find.text('Your data stays yours'), findsOneWidget);
      expect(
        find.textContaining('no messages, website addresses, window titles'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Choose what FlowWave may use'), findsOneWidget);
      for (final type in ConsentType.values) {
        final tile = tester.widget<SwitchListTile>(
          find.descendant(
            of: find.byKey(ValueKey('consent-${type.wireName}')),
            matching: find.byType(SwitchListTile),
          ),
        );
        expect(tile.value, isFalse, reason: '$type is off by default');
      }
      await tester.tap(find.byKey(const ValueKey('consent-notifications')));
      await tester.pumpAndSettle();

      final log = await app.container.read(consentRepositoryProvider).log();
      expect(log.single.type, ConsentType.notifications);
      expect(log.single.decidedAt.timeZone, 'Europe/Warsaw');
      expect(
        await app.container.read(outboxRepositoryProvider).summary(),
        const OutboxSummary(),
        reason: 'nothing is queued while signed out',
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Short check-ins'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Create account'), findsOneWidget);
      await tester.tap(find.text('Continue without account'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsWidgets);
      expect(
        find.text(
          'FlowWave shows personal rhythm estimates based on the data you '
          'choose to share. They are not medical assessments or diagnoses.',
        ),
        findsOneWidget,
      );
      expect(
        (await app.container.read(settingsRepositoryProvider).load())
            .onboardingCompleted,
        isTrue,
      );
    },
  );

  testWidgets('health data offers its scopes once switched on', (tester) async {
    final app = TestApp();
    await app.pump(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('consent-health_data')));
    await tester.pumpAndSettle();
    expect(find.text('Steps'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scope-steps')));
    await tester.pumpAndSettle();

    final log = await app.container.read(consentRepositoryProvider).log();
    expect(log, hasLength(2));
    expect(log.last.scopes, [
      'heart_rate',
      'resting_heart_rate',
      'sleep_duration',
    ]);
    expect(log.last.sourceId, healthConnectSourceId);
  });

  testWidgets('a returning user goes straight to Today; tabs switch', (
    tester,
  ) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Check-in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('record how your energy'), findsOneWidget);
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('in order, at the local time'), findsOneWidget);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.textContaining('factors they are based on'), findsOneWidget);
  });

  testWidgets(
    'without a server, onboarding explains accounts are unavailable',
    (tester) async {
      final app = TestApp(apiConfigured: false);
      await app.pump(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsNothing);
      expect(find.textContaining('Accounts are not available'), findsOneWidget);
    },
  );
}
