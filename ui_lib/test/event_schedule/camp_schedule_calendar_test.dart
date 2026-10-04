import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/event_schedule/camp_schedule_calendar.dart';

Future<void> _pump(
  WidgetTester tester, {
  required DateTime startDate,
  required int durationDays,
  Set<DateTime> excludedDates = const {},
}) async {
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CampScheduleCalendar(
            startDate: startDate,
            durationDays: durationDays,
            excludedDates: excludedDates,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 705: renders the camp month label and day numbers', (
    tester,
  ) async {
    await _pump(tester, startDate: DateTime(2026, 8), durationDays: 5);

    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('Camp day'), findsOneWidget);
    // Camp days 1..5 are rendered.
    for (final d in ['1', '2', '3', '4', '5']) {
      expect(find.text(d), findsWidgets);
    }
  });

  testWidgets('Issue 705: bounds to the camp weeks, not a full month', (
    tester,
  ) async {
    await _pump(tester, startDate: DateTime(2026, 8), durationDays: 5);

    // A day well outside the camp weeks (Aug 20) is never drawn.
    expect(find.text('20'), findsNothing);
  });

  testWidgets('Issue 705: strikes through a rest day and shows its legend', (
    tester,
  ) async {
    await _pump(
      tester,
      startDate: DateTime(2026, 8),
      durationDays: 5,
      excludedDates: {DateTime(2026, 8, 3)},
    );

    expect(find.text('Rest day'), findsOneWidget);
    final restDay = tester.widget<Text>(find.text('3'));
    expect(restDay.style?.decoration, TextDecoration.lineThrough);
    final campDay = tester.widget<Text>(find.text('4'));
    expect(campDay.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('Issue 705: no rest-day legend when nothing is excluded', (
    tester,
  ) async {
    await _pump(tester, startDate: DateTime(2026, 8), durationDays: 5);
    expect(find.text('Rest day'), findsNothing);
  });
}
