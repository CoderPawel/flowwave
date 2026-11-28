import 'package:flowwave_mobile/src/app/router.dart';
import 'package:flowwave_mobile/src/app/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

Future<void> _meetsGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  testWidgets('welcome flow screens meet tap target and label guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = TestApp();
    await app.pump(tester);
    await _meetsGuidelines(tester);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    await _meetsGuidelines(tester);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);
    await _meetsGuidelines(tester);
    handle.dispose();
  });

  testWidgets('main screens meet tap target and label guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);

    expect(find.byTooltip('Settings'), findsOneWidget);
    await _meetsGuidelines(tester);
    for (final tab in ['Check-in', 'Timeline', 'Insights']) {
      await tester.tap(find.text(tab));
      await settle(tester);
      await _meetsGuidelines(tester);
    }

    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await _meetsGuidelines(tester);
    await tapInList(tester, find.text('Data and privacy'));
    await _meetsGuidelines(tester);
    handle.dispose();
  });

  testWidgets('sign-in form fields and the password toggle are labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);
    app.container.read(routerProvider).go(Routes.settingsLogin);
    await settle(tester);

    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip('Show password')),
      matchesSemantics(
        tooltip: 'Show password',
        isButton: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await _meetsGuidelines(tester);

    await tester.tap(find.byTooltip('Show password'));
    await settle(tester);
    expect(find.byTooltip('Hide password'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('screens still lay out with very large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = TestApp();
    await app.pump(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics tree exposes headings on the privacy intro', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final app = TestApp();
    await app.pump(tester);
    final heading = tester.getSemantics(find.text('Your data stays yours'));
    expect(heading.flagsCollection.isHeader, isTrue);
    handle.dispose();
  });
}
