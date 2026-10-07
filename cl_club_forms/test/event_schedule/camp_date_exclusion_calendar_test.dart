import 'package:cl_club_forms/src/widgets/event_schedule/camp_date_exclusion_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/form_harness.dart';

/// A camp of five days from Monday 3 August 2026 unless told otherwise,
/// with what the calendar reported last.
class _Host {
  Set<DateTime>? reported;
  int calls = 0;

  Widget build({
    DateTime? start,
    int durationDays = 5,
    Set<DateTime> excluded = const {},
    bool enabled = true,
  }) => CampDateExclusionCalendar(
    campStartDate: start ?? DateTime(2026, 8, 3),
    durationDays: durationDays,
    excludedDates: excluded,
    enabled: enabled,
    onChanged: (dates) {
      calls++;
      reported = dates;
    },
  );
}

Text _dayText(WidgetTester tester, int day) =>
    tester.widget<Text>(restDayCell(day));

void main() {
  testWidgets('Issue 61: it opens on the month the camp starts in, weeks '
      'from Monday', (tester) async {
    await pumpForm(tester, _Host().build());

    expect(find.text('August 2026'), findsOneWidget);
    for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(label), findsOneWidget);
    }
    // 1 August 2026 is a Saturday: the sixth cell of the first week.
    final first = tester.getTopLeft(restDayCell(1));
    expect(first.dx, greaterThan(tester.getTopLeft(find.text('Fri')).dx));
    expect(first.dx, lessThan(tester.getTopLeft(find.text('Sun')).dx));
    expect(find.text('Camp days'), findsOneWidget);
    expect(find.text('Excluded (rest days)'), findsOneWidget);
  });

  testWidgets('Issue 61: the days of the camp are set apart from the rest '
      'of the month', (tester) async {
    await pumpForm(tester, _Host().build());

    // 3..7 August are camp days, 2 and 8 are not.
    for (final day in [3, 7]) {
      expect(_dayText(tester, day).style!.fontWeight, FontWeight.w600);
    }
    for (final day in [2, 8]) {
      expect(_dayText(tester, day).style!.fontWeight, FontWeight.normal);
    }
  });

  testWidgets('Issue 61: tapping a camp day reports it as a rest day, at '
      'midnight', (tester) async {
    final host = _Host();
    await pumpForm(
      tester,
      host.build(excluded: {DateTime(2026, 8, 4)}),
    );

    await tapRestDay(tester, 6);

    expect(host.reported, {DateTime(2026, 8, 4), DateTime(2026, 8, 6)});
  });

  testWidgets('Issue 61: tapping a rest day reports it as a camp day again, '
      'whatever time of day it was stored with', (tester) async {
    final host = _Host();
    await pumpForm(
      tester,
      host.build(
        excluded: {DateTime(2026, 8, 4, 13, 30), DateTime(2026, 8, 6)},
      ),
    );

    await tapRestDay(tester, 4);

    expect(host.reported, {DateTime(2026, 8, 6)});
  });

  testWidgets('Issue 61: a rest day is struck through and marked, a camp '
      'day is not', (tester) async {
    await pumpForm(
      tester,
      _Host().build(excluded: {DateTime(2026, 8, 5)}),
    );

    expect(_dayText(tester, 5).style!.decoration, TextDecoration.lineThrough);
    expect(
      _dayText(tester, 4).style!.decoration,
      isNot(TextDecoration.lineThrough),
    );
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('Issue 61: the calendar does not change the set it was given', (
    tester,
  ) async {
    final host = _Host();
    final given = {DateTime(2026, 8, 4)};
    await pumpForm(tester, host.build(excluded: given));

    await tapRestDay(tester, 6);

    expect(given, {DateTime(2026, 8, 4)});
    expect(host.reported, isNot(same(given)));
  });

  testWidgets('Issue 61: a day outside the camp does not respond: the day '
      'before, the day after, and a day of the next month', (tester) async {
    final host = _Host();
    await pumpForm(tester, host.build());

    await tapRestDay(tester, 2);
    await tapRestDay(tester, 8);
    // 3 September shows in the last week of the August grid.
    await tester.tap(
      find
          .descendant(
            of: find.byType(CampDateExclusionCalendar),
            matching: find.text('3'),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(host.calls, 0);
  });

  testWidgets('Issue 61: the first and the last day of the camp respond', (
    tester,
  ) async {
    final host = _Host();
    await pumpForm(tester, host.build());

    await tapRestDay(tester, 3);
    expect(host.reported, {DateTime(2026, 8, 3)});
    await tapRestDay(tester, 7);
    expect(host.reported, {DateTime(2026, 8, 7)});
  });

  testWidgets('Issue 61: with enabled false no day responds', (tester) async {
    final host = _Host();
    await pumpForm(
      tester,
      host.build(excluded: {DateTime(2026, 8, 5)}, enabled: false),
    );

    await tapRestDay(tester, 4);
    await tapRestDay(tester, 5);

    expect(host.calls, 0);
  });

  testWidgets('Issue 61: the arrows move a month at a time, across the '
      'year end', (tester) async {
    await pumpForm(tester, _Host().build(start: DateTime(2026, 12, 28)));
    expect(find.text('December 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('January 2027'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('Issue 61: a camp running into the next month has its days '
      'there, and they toggle', (tester) async {
    final host = _Host();
    await pumpForm(
      tester,
      host.build(start: DateTime(2026, 8, 28), durationDays: 7),
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);

    // The camp ends on 3 September.
    await tapRestDay(tester, 4);
    expect(host.calls, 0);
    await tapRestDay(tester, 3);
    expect(host.reported, {DateTime(2026, 9, 3)});
  });

  testWidgets('Issue 61: a new start date brings its month into view', (
    tester,
  ) async {
    final host = _Host();
    await pumpForm(tester, host.build());
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);

    await pumpForm(tester, host.build(start: DateTime(2027, 2, 1)));

    expect(find.text('February 2027'), findsOneWidget);
  });

  testWidgets('Issue 61: a longer camp widens the days that respond', (
    tester,
  ) async {
    final host = _Host();
    await pumpForm(tester, host.build());
    await tapRestDay(tester, 8);
    expect(host.calls, 0);

    await pumpForm(tester, host.build(durationDays: 6));
    await tapRestDay(tester, 8);

    expect(host.reported, {DateTime(2026, 8, 8)});
  });

  testWidgets('Issue 61: a six-week month fits a phone', (tester) async {
    // August 2026 starts on a Saturday and ends on a Monday: six weeks.
    await pumpForm(
      tester,
      _Host().build(excluded: {DateTime(2026, 8, 5)}),
      size: kPhoneSurface,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('31'), findsWidgets);
    expect(
      tester.getSize(find.byType(CampDateExclusionCalendar)).width,
      lessThanOrEqualTo(kPhoneSurface.width - 32),
    );
  });
}
