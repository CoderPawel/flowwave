import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // A tap that misses its widget is a broken test, not a warning.
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
