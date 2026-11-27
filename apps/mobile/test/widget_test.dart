import 'package:flowwave_mobile/src/app.dart';
import 'package:flowwave_mobile/src/home/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'home screen shows the app title and the non-medical disclaimer',
    (tester) async {
      await tester.pumpWidget(const FlowWaveApp());

      expect(find.text('FlowWave'), findsOneWidget);
      expect(find.text('Your energy and focus rhythm'), findsOneWidget);
      expect(find.text(HomeScreen.disclaimer), findsOneWidget);
    },
  );
}
