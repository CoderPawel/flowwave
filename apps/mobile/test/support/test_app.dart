import 'package:drift/drift.dart' show Value;
import 'package:flowwave_mobile/src/app/flowwave_app.dart';
import 'package:flowwave_mobile/src/app/providers.dart';
import 'package:flowwave_mobile/src/core/database/app_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_fakes.dart';
import 'fake_http_adapter.dart';
import 'test_database.dart';

/// The whole app with an in-memory database, in-memory tokens, a fixed
/// clock and a fake server.
class TestApp {
  TestApp({this.apiConfigured = true, this._opener});

  final bool apiConfigured;
  final Future<AppDatabase> Function()? _opener;
  final AppDatabase db = inMemoryDatabase();
  final InMemoryTokenStore tokens = InMemoryTokenStore();
  final FakeHttpAdapter server = FakeHttpAdapter();
  final FixedZonedClock clock = FixedZonedClock();
  int resets = 0;

  late ProviderContainer container;

  /// Marks onboarding complete, as for a returning user.
  Future<void> completeOnboarding() async {
    await db
        .update(db.localSettings)
        .write(
          LocalSettingsCompanion(
            onboardingCompletedAtUtc: Value(DateTime.utc(2026, 11, 27)),
          ),
        );
  }

  Future<void> signIn() async {
    tokens.tokens = tokensFor(1, clock.current);
  }

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    addTearDown(db.close);
    if (locale != null) {
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseOpenerProvider.overrideWithValue(_opener ?? () async => db),
          databaseResetterProvider.overrideWithValue(() async => resets += 1),
          tokenStoreProvider.overrideWithValue(tokens),
          zonedClockProvider.overrideWithValue(clock),
          apiBaseUrlProvider.overrideWithValue(
            apiConfigured ? testBaseUrl : null,
          ),
          httpClientAdapterProvider.overrideWithValue(server),
        ],
        child: const FlowWaveApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(FlowWaveApp)),
    );
    await settle(tester);
  }
}

/// Like `pumpAndSettle`, but also lets timer-driven work finish: database
/// queries and background sync complete on timers, which `pumpAndSettle`
/// does not advance once no frame is scheduled.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Scrolls [finder] fully into view in the screen's list, then taps it.
Future<void> tapInList(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200);
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}
