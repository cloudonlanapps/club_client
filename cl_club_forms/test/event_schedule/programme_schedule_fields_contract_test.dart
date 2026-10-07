// ProgrammeScheduleFormField is a field cluster, hosted by the event create
// form and ProgrammeScheduleAdjustForm: `validate()`, `isDirty` and
// `showErrors` belong to those forms and are tested there. This file adds to
// programme_schedule_fields_test.dart what issue 61 asks of a cluster: its
// rows, each rule's message where the user sees it, the value it builds from
// what is typed, `showDateRange`, `enabled: false` and phone width.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/src/models/programme_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart';
import 'package:cl_club_forms/src/widgets/form/labeled_form_row.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_schedule_cluster.dart';
import '../support/programme_timetable_support.dart';

/// [message] shown inside the row labelled [label].
Finder _inRow(String label, String message) => find.descendant(
  of: find.byWidgetPredicate((w) => w is LabeledFormRow && w.label == label),
  matching: find.text(message),
);

void main() {
  group('Issue 61: ProgrammeScheduleFormField rows', () {
    testWidgets('Issue 61: with the date range its rows are the days, the '
        'two dates, the time, the duration and the sessions', (tester) async {
      await pumpProgrammeField(tester);

      // End Date is labelled by a row too, with its Clear button beside the
      // label; it is the one optional date.
      expect(rowLabels(tester), [
        'Days of Week *',
        'Start Date *',
        'Start Time *',
        'Duration *',
        'Sessions',
      ]);
      expect(
        find.descendant(
          of: find.byType(LabeledFormRow),
          matching: find.text('End Date'),
        ),
        findsOneWidget,
      );
      expect(find.text('Ongoing'), findsOneWidget);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: without the date range neither date shows, and '
        'the value keeps the seeded dates', (tester) async {
      final seeded = validProgramme.copyWith(
        endDate: () => DateTime(2030, 9),
        hasNoEndDate: false,
      );
      final form = await pumpProgrammeField(
        tester,
        initialValue: seeded,
        showDateRange: false,
      );

      expect(rowLabels(tester), [
        'Days of Week *',
        'Start Time *',
        'Duration *',
        'Sessions',
      ]);
      expect(find.byType(CLDatePickerFormField), findsNothing);
      expect(find.text('End Date'), findsNothing);
      expect(find.text('Clear'), findsNothing);

      await tester.tap(find.byType(WeekdayChip).at(2));
      await tester.pumpAndSettle();
      expect(
        programmeValue(form),
        seeded.copyWith(weekdays: {DateTime.monday, DateTime.wednesday}),
      );
    });

    testWidgets('Issue 61: wide, the dates share a row and so do the time '
        'and duration; on a phone each has its own', (tester) async {
      await pumpProgrammeField(tester, initialValue: validProgramme);
      Offset at(String text) => tester.getTopLeft(find.text(text));
      expect(at('Start Date *').dy, at('End Date').dy);
      expect(at('Start Time *').dy, at('Duration *').dy);

      await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);
      expect(at('End Date').dy, greaterThan(at('Start Date *').dy));
      expect(at('Duration *').dy, greaterThan(at('Start Time *').dy));
      expect(at('End Date').dx, at('Start Date *').dx);
    });

    testWidgets('Issue 61: a split and an end date fit a phone', (
      tester,
    ) async {
      await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(
          endDate: () => DateTime(2030, 9),
          hasNoEndDate: false,
          sessions: const [
            SessionInput(
              name: 'Off-ice warm-up and stretching',
              startTime: '09:00',
              endTime: '09:30',
            ),
            SessionInput(name: 'On-ice', startTime: '09:30', endTime: '11:00'),
          ],
        ),
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Clear'), findsOneWidget);
      expect(shownDurations(tester), ['0:30', '1:30']);
    });
  });

  group('Issue 61: ProgrammeScheduleFormField messages', () {
    testWidgets('Issue 61: no weekday is refused under the days', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(weekdays: const <int>{}),
      );

      expect(await validateProgramme(tester, form), isFalse);
      expect(
        _inRow('Days of Week', 'Pick at least one day'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: no start date is refused on Start Date', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(startDate: () => null),
      );

      expect(await validateProgramme(tester, form), isFalse);
      expect(_inRow('Start Date', 'Start date is required'), findsOneWidget);
    });

    testWidgets('Issue 61: no start time is refused on Start Time', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(sessionStartTime: () => null),
      );

      expect(await validateProgramme(tester, form), isFalse);
      expect(_inRow('Start Time', 'Start time is required'), findsOneWidget);
    });

    testWidgets('Issue 61: an end date before the start is refused, the '
        'start day itself is accepted', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      await pickProgrammeDate(tester, 1, DateTime(2030, 5, 5));
      expect(await validateProgramme(tester, form), isFalse);
      expect(find.text('End date must be after start date'), findsWidgets);

      await pickProgrammeDate(tester, 1, DateTime(2030, 5, 6));
      expect(await validateProgramme(tester, form), isTrue);
      expect(find.text('End date must be after start date'), findsNothing);
      expect(programmeValue(form).endDate, DateTime(2030, 5, 6));
      expect(programmeValue(form).hasNoEndDate, isFalse);
    });

    testWidgets('Issue 61: a duration that is nothing or unreadable is '
        'refused on Duration', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      for (final typed in ['0', '0m', '', 'two hours']) {
        await enterDuration(tester, typed);
        expect(
          await validateProgramme(tester, form),
          isFalse,
          reason: '"$typed"',
        );
        expect(
          _inRow('Duration', 'Duration must be greater than 0'),
          findsOneWidget,
        );
      }
    });

    testWidgets('Issue 61: a duration over four hours is refused on '
        'Duration', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      await enterDuration(tester, '241m');

      expect(await validateProgramme(tester, form), isFalse);
      expect(
        _inRow('Duration', 'Programme session cannot exceed 4h'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: a duration of exactly four hours is accepted', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      await enterDuration(tester, '240m');

      expect(await validateProgramme(tester, form), isTrue);
      expect(programmeValue(form).totalDurationMinutes, 240);
    });
  });

  group('Issue 61: ProgrammeScheduleFormField.aggregateValidator bounds', () {
    const check = ProgrammeScheduleFormField.aggregateValidator;

    test('Issue 61: four hours pass, a minute more does not', () {
      expect(check(validProgramme.copyWith(totalDurationMinutes: 240)), isNull);
      expect(
        check(validProgramme.copyWith(totalDurationMinutes: 241)),
        'Programme session cannot exceed 4h',
      );
      expect(maxProgrammeDurationMinutes, 240);
    });

    test('Issue 61: one minute passes, none does not', () {
      expect(check(validProgramme.copyWith(totalDurationMinutes: 1)), isNull);
      expect(
        check(validProgramme.copyWith(totalDurationMinutes: 0)),
        'Duration must be greater than 0',
      );
    });

    test('Issue 61: an end on the start day passes, the day before does '
        'not', () {
      ProgrammeScheduleData ending(DateTime day) =>
          validProgramme.copyWith(endDate: () => day, hasNoEndDate: false);
      expect(check(ending(DateTime(2030, 5, 6))), isNull);
      expect(
        check(ending(DateTime(2030, 5, 5))),
        'End date must be after start date',
      );
    });

    test('Issue 61: the first broken rule is the one reported', () {
      expect(check(const ProgrammeScheduleData()), 'Pick at least one day');
      expect(
        check(const ProgrammeScheduleData(weekdays: {1})),
        'Start date is required',
      );
      expect(
        check(
          ProgrammeScheduleData(weekdays: const {1}, startDate: DateTime(2030)),
        ),
        'Start time is required',
      );
    });
  });
}
