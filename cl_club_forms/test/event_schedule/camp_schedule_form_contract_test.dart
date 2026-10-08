// CampScheduleForm against the form contract (issue 61).
//
// Not applicable: the form has no rule across fields (`crossFieldError` is
// not overridden; the session split adds up by construction), and no
// parameter hides or locks a field. The rest-days row is the one row that
// comes and goes, with the start date. In-form actions: the calendar's
// month arrows and a split session's remove button (icon buttons, no text).
import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_date_exclusion_calendar.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const String _id = CampScheduleFormFields.scheduleId;

CampScheduleData _seed({
  Set<DateTime> excludedDates = const {},
  List<SessionInput> sessions = const [],
}) => CampScheduleData(
  startDate: DateTime(2026, 8, 3),
  trainingDays: 5,
  sessionStartTime: timeAt(6),
  durationMinutes: 120,
  excludedDates: excludedDates,
  sessions: sessions,
);

const _split = [
  SessionInput(name: 'Off-Ice', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'On-Ice', startTime: '06:30', endTime: '08:00'),
];

Future<CampScheduleFormState> _pump(
  WidgetTester tester,
  CampScheduleData initial, {
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  await pumpForm(
    tester,
    CampScheduleForm(initialValue: initial, enabled: enabled),
    size: size,
  );
  return tester.state<CampScheduleFormState>(find.byType(CampScheduleForm));
}

CampScheduleFormFieldBodyState _body(WidgetTester tester) =>
    tester.state<CampScheduleFormFieldBodyState>(
      find.byType(CampScheduleFormFieldBody),
    );

CampScheduleData _valueOf(Map<String, dynamic>? values) =>
    values![_id] as CampScheduleData;

void main() {
  group('CampScheduleForm fields', () {
    testWidgets('Issue 61: every input is a labelled row, the required ones '
        'marked', (tester) async {
      await _pump(tester, _seed());

      expect(rowLabels(tester), [
        'Start Date *',
        'Training Days *',
        'Start Time *',
        'Duration *',
        'Sessions',
        'Rest Days (tap to toggle)',
      ]);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: the rest days row waits for a start date', (
      tester,
    ) async {
      await _pump(tester, const CampScheduleData());

      expect(rowLabels(tester), isNot(contains('Rest Days (tap to toggle)')));
      expect(find.byType(CampDateExclusionCalendar), findsNothing);

      await pickScheduleDate(tester, DateTime(2026, 8, 3));

      expect(rowLabels(tester).last, 'Rest Days (tap to toggle)');
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('Issue 61: the form draws no button of the host', (
      tester,
    ) async {
      await _pump(tester, _seed(sessions: _split));

      expectNoHostChrome(tester);
      // Its only buttons are in-form: the month arrows and one remove
      // button per split session.
      expect(find.byType(IconButton), findsNWidgets(4));
    });
  });

  group('CampScheduleForm field validation', () {
    testWidgets('Issue 61: a missing start date is refused on its row', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        _seed().copyWith(startDate: () => null),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        textInRow('Start Date', 'Start date is required'),
        findsOneWidget,
      );

      await pickScheduleDate(tester, DateTime(2026, 8, 3));
      expect(_valueOf(state.validate()).startDate, DateTime(2026, 8, 3));
    });

    testWidgets('Issue 61: a missing start time is refused on its row', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        _seed().copyWith(sessionStartTime: () => null),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        textInRow('Start Time', 'Start time is required'),
        findsOneWidget,
      );

      await pickScheduleStartTime(tester, timeAt(7, 30));
      expect(_valueOf(state.validate()).sessionStartTime, timeAt(7, 30));
    });

    testWidgets('Issue 61: empty training days are refused as required', (
      tester,
    ) async {
      final state = await _pump(tester, _seed());

      await typeInRow(tester, 'Training Days', '');
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(textInRow('Training Days', 'Required'), findsOneWidget);
    });

    for (final bad in ['0', '-2', 'five', '2.5']) {
      testWidgets('Issue 61: training days "$bad" are refused as not a '
          'number of days', (tester) async {
        final state = await _pump(tester, _seed());

        await typeInRow(tester, 'Training Days', bad);
        expect(state.validate(), isNull);
        await tester.pumpAndSettle();
        expect(
          textInRow('Training Days', 'Enter a valid number'),
          findsOneWidget,
        );
      });
    }

    testWidgets('Issue 61: one training day, the least allowed, is accepted', (
      tester,
    ) async {
      final state = await _pump(tester, _seed());

      await typeInRow(tester, 'Training Days', '1');
      expect(_valueOf(state.validate()).trainingDays, 1);
    });

    testWidgets('Issue 61: a refused input is accepted once corrected', (
      tester,
    ) async {
      final state = await _pump(tester, _seed());

      await typeInRow(tester, 'Training Days', 'soon');
      expect(state.validate(), isNull);

      await typeInRow(tester, 'Training Days', '4');
      expect(_valueOf(state.validate()).trainingDays, 4);
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid number'), findsNothing);
    });
  });

  group('CampScheduleForm values', () {
    testWidgets('Issue 61: validate returns the one key, a CampScheduleData '
        'equal to the seed, rest days and split included', (tester) async {
      final initial = _seed(
        excludedDates: {DateTime(2026, 8, 5)},
        sessions: _split,
      );
      final state = await _pump(tester, initial);

      final values = state.validate();

      expect(values!.keys, [_id]);
      expect(values[_id], isA<CampScheduleData>());
      expect(values[_id], initial);
    });

    testWidgets('Issue 61: what the user enters comes back assembled', (
      tester,
    ) async {
      final state = await _pump(tester, const CampScheduleData());

      await pickScheduleDate(tester, DateTime(2026, 9, 7));
      await pickScheduleStartTime(tester, timeAt(17, 15));
      await typeInRow(tester, 'Training Days', '3');
      await pickDuration(tester, 1, 30);
      await tapRestDay(tester, 8);

      expect(
        _valueOf(state.validate()),
        CampScheduleData(
          startDate: DateTime(2026, 9, 7),
          trainingDays: 3,
          sessionStartTime: timeAt(17, 15),
          durationMinutes: 90,
          excludedDates: {DateTime(2026, 9, 8)},
        ),
      );
    });

    testWidgets('Issue 61: an undivided day comes back with no sessions, a '
        'split one with named sessions walked from the start time', (
      tester,
    ) async {
      final state = await _pump(tester, _seed());
      expect(_valueOf(state.validate()).sessions, isEmpty);

      _body(tester).onSessionDurationChanged(0, const Duration(minutes: 45));
      await tester.pumpAndSettle();
      await typeInRow(tester, 'Sessions', '  Warm-up ');

      expect(_valueOf(state.validate()).sessions, const [
        SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:45'),
        SessionInput(name: 'Session 2', startTime: '06:45', endTime: '08:00'),
      ]);
    });
  });
}
