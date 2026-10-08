// CampScheduleFormField, the camp cluster shared by the create form and
// CampScheduleForm, driven through its inputs (issue 61). Its handlers and
// its aggregate validator are covered in camp_schedule_fields_test.dart.
import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_date_exclusion_calendar.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const _id = 'schedule';

/// The cluster in a bare `ShadForm`, with what its `onChanged` reported.
class _Host {
  final formKey = GlobalKey<ShadFormState>();
  final reported = <CampScheduleData?>[];

  Widget build({CampScheduleData? initial, bool enabled = true}) => ShadForm(
    key: formKey,
    child: CampScheduleFormField(
      id: _id,
      initialValue: initial,
      enabled: enabled,
      validator: CampScheduleFormField.aggregateValidator,
      onChanged: reported.add,
    ),
  );

  CampScheduleData? get value =>
      formKey.currentState!.value[_id] as CampScheduleData?;
}

CampScheduleData _seed({List<SessionInput> sessions = const []}) =>
    CampScheduleData(
      startDate: DateTime(2026, 8, 3),
      trainingDays: 5,
      sessionStartTime: timeAt(9),
      sessions: sessions,
    );

const _split = [
  SessionInput(name: 'Off-Ice', startTime: '09:00', endTime: '09:30'),
  SessionInput(name: 'On-Ice', startTime: '09:30', endTime: '11:00'),
];

void main() {
  group('CampScheduleFormField.aggregateValidator bounds', () {
    test(
      'Issue 61: one training day and one minute are the least accepted',
      () {
        final least = CampScheduleData(
          startDate: DateTime(2026),
          trainingDays: 1,
          sessionStartTime: timeAt(0),
          durationMinutes: 1,
        );
        expect(CampScheduleFormField.aggregateValidator(least), isNull);
        expect(
          CampScheduleFormField.aggregateValidator(
            least.copyWith(trainingDays: 0),
          ),
          'Training days must be at least 1',
        );
        expect(
          CampScheduleFormField.aggregateValidator(
            least.copyWith(durationMinutes: 0),
          ),
          'Duration must be greater than 0',
        );
      },
    );

    test('Issue 61: of several faults the first in form order is reported', () {
      expect(
        CampScheduleFormField.aggregateValidator(
          const CampScheduleData(trainingDays: 0, durationMinutes: 0),
        ),
        'Start date is required',
      );
      expect(
        CampScheduleFormField.aggregateValidator(
          CampScheduleData(
            startDate: DateTime(2026),
            trainingDays: 0,
            durationMinutes: 0,
          ),
        ),
        'Training days must be at least 1',
      );
    });
  });

  group('CampScheduleFormField inputs', () {
    testWidgets('Issue 61: its rows are labelled rows, the four required '
        'ones marked', (tester) async {
      await pumpForm(tester, _Host().build(initial: _seed()));

      expect(rowLabels(tester), [
        'Start Date *',
        'Training Days *',
        'Start Time *',
        'Duration *',
        'Sessions',
        'Rest Days (tap to toggle)',
      ]);
    });

    testWidgets('Issue 61: an empty cluster opens on seven days of two '
        'hours, and holds no value until an input changes', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build());

      expect(host.value, isNull);
      expect(textInRow('Training Days', '7'), findsOneWidget);
      expect(textInRow('Duration', '2:00'), findsOneWidget);

      await pickScheduleDate(tester, DateTime(2026, 8, 3));

      expect(host.value, CampScheduleData(startDate: DateTime(2026, 8, 3)));
    });

    testWidgets('Issue 61: typing the hour alone gives a start time on the '
        'hour, typing the minutes completes it', (tester) async {
      final host = _Host();
      await pumpForm(
        tester,
        host.build(initial: CampScheduleData(startDate: DateTime(2026, 8, 3))),
      );
      final boxes = find.descendant(
        of: scheduleRow('Start Time'),
        matching: find.byType(EditableText),
      );
      expect(boxes, findsNWidgets(2), reason: 'hours and minutes, no seconds');

      await tester.enterText(boxes.first, '9');
      await tester.pumpAndSettle();
      expect(host.value!.sessionStartTime, timeAt(9));

      await tester.enterText(boxes.last, '45');
      await tester.pumpAndSettle();
      expect(host.value!.sessionStartTime, timeAt(9, 45));
    });

    testWidgets('Issue 61: every edit is reported to the host with the '
        'whole schedule', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));

      await typeInRow(tester, 'Training Days', '4');
      expect(host.reported.last, _seed().copyWith(trainingDays: 4));

      await pickDuration(tester, 1);
      expect(
        host.reported.last,
        _seed().copyWith(trainingDays: 4, durationMinutes: 60),
      );
      expect(host.reported, hasLength(2));
    });

    testWidgets('Issue 61: an entry that is not a number of days or a '
        'duration is not reported and keeps the last good value', (
      tester,
    ) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));

      await typeInRow(tester, 'Training Days', '0');
      await typeInRow(tester, 'Training Days', 'x');

      expect(host.reported, isEmpty);
      expect(host.value, _seed());
    });

    testWidgets('Issue 61: a new duration resets a split to one session', (
      tester,
    ) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed(sessions: _split)));
      expect(
        tester
            .state<SessionSplitFieldState>(find.byType(SessionSplitField))
            .sessionDurations,
        [30, 90],
      );

      await pickDuration(tester, 3);

      expect(host.value!.sessions, isEmpty);
      expect(
        tester
            .state<SessionSplitFieldState>(find.byType(SessionSplitField))
            .sessionDurations,
        [180],
      );
    });

    testWidgets('Issue 61: a rest day joins the value and lengthens the '
        'camp by a day, the training days unchanged', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));
      CampDateExclusionCalendar calendar() => tester.widget(
        find.byType(CampDateExclusionCalendar),
      );
      expect(calendar().durationDays, 5);

      await tapRestDay(tester, 5);

      expect(host.value!.excludedDates, {DateTime(2026, 8, 5)});
      expect(host.value!.trainingDays, 5);
      expect(calendar().durationDays, 6);
      // 8 August, outside the five days, is now the camp's last day.
      await tapRestDay(tester, 8);
      expect(host.value!.excludedDates, {
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 8),
      });
    });

    testWidgets('Issue 61: more training days widen the days that can be '
        'rest days', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));

      await tapRestDay(tester, 10);
      expect(host.reported, isEmpty, reason: '10 August is past the camp');

      await typeInRow(tester, 'Training Days', '8');
      await tapRestDay(tester, 10);

      expect(host.value!.excludedDates, {DateTime(2026, 8, 10)});
    });

    testWidgets('Issue 61: a new start date moves the calendar to its '
        'month', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));
      expect(find.text('August 2026'), findsOneWidget);

      await pickScheduleDate(tester, DateTime(2026, 11, 2));

      expect(find.text('November 2026'), findsOneWidget);
      expect(host.value!.startDate, DateTime(2026, 11, 2));
    });

    testWidgets('Issue 61: validating an empty cluster puts each message '
        'on its own row', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build());

      await typeInRow(tester, 'Training Days', '');
      expect(host.formKey.currentState!.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();

      expect(
        textInRow('Start Date', 'Start date is required'),
        findsOneWidget,
      );
      expect(textInRow('Training Days', 'Required'), findsOneWidget);
      expect(
        textInRow('Start Time', 'Start time is required'),
        findsOneWidget,
      );
    });
  });

  group('CampScheduleFormField layout', () {
    testWidgets('Issue 61: on a wide surface the date and days share a '
        'row, and so do the start time and duration', (tester) async {
      await pumpForm(tester, _Host().build(initial: _seed()));

      for (final (left, right) in [
        ('Start Date', 'Training Days'),
        ('Start Time', 'Duration'),
      ]) {
        final a = tester.getTopLeft(scheduleRow(left));
        final b = tester.getTopLeft(scheduleRow(right));
        expect(b.dy, a.dy, reason: '$left and $right');
        expect(b.dx, greaterThan(a.dx));
      }
    });

    testWidgets('Issue 61: at phone width every row stacks in one column '
        'and nothing overflows', (tester) async {
      await pumpForm(
        tester,
        _Host().build(initial: _seed(sessions: _split)),
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
      var last = tester.getTopLeft(scheduleRow('Start Date'));
      for (final label in [
        'Training Days',
        'Start Time',
        'Duration',
        'Sessions',
        'Rest Days (tap to toggle)',
      ]) {
        final next = tester.getTopLeft(scheduleRow(label));
        expect(next.dx, last.dx, reason: label);
        expect(next.dy, greaterThan(last.dy), reason: label);
        last = next;
      }
    });
  });
}
