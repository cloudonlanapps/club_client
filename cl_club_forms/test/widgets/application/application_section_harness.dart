import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_harness.dart';

/// The checks every application section form gets once its own are done:
/// a refusal shows where it belongs, the form turned off takes no input,
/// and it fits a phone. [build] gives the form with `enabled` on or off.
Future<void> expectSectionFormBasics(
  WidgetTester tester,
  Widget Function({required bool enabled}) build,
) async {
  expect(await expectDrawnOffWhenTurnedOff(tester, build), greaterThan(0));
  await expectKeyboardIgnoredWhenOff(tester, build);
  await expectFitsPhone(tester, build(enabled: true));
}
