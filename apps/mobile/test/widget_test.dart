import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('a returning user lands on Today with the non-medical '
      'disclaimer', (tester) async {
    final app = TestApp();
    await app.completeOnboarding();
    await app.pump(tester);

    expect(find.text('Today'), findsWidgets);
    expect(
      find.text(
        'FlowWave shows personal rhythm estimates based on the data you '
        'choose to share. They are not medical assessments or diagnoses.',
      ),
      findsOneWidget,
    );
  });
}
