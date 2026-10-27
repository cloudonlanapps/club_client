import 'package:flutter_test/flutter_test.dart';

/// Taps [trigger], a date input, expects its calendar to open on a month
/// that shows [day] once, and picks [day].
Future<void> pickDayOn(WidgetTester tester, Finder trigger, int day) async {
  await tester.ensureVisible(trigger);
  await tester.pumpAndSettle();
  expect(find.text('$day'), findsNothing, reason: 'the calendar is closed');
  await tester.tap(trigger);
  await tester.pumpAndSettle();
  expect(find.text('$day'), findsOneWidget, reason: 'the calendar opened');
  await tester.tap(find.text('$day'));
  await tester.pumpAndSettle();
  expect(find.text('$day'), findsNothing, reason: 'the calendar closed');
}
