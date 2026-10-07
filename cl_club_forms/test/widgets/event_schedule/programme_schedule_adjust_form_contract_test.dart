// The values, dirty check and host contract of ProgrammeScheduleAdjustForm;
// its fields and validation are in
// programme_schedule_adjust_form_fields_test.dart, which also notes the
// points of issue 61 that do not apply to this form.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart'
    show WeekdayChip;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';
import '../../support/programme_timetable_adjust_fixtures.dart';
import '../../support/programme_timetable_support.dart';

Finder _onField(String id, String message) =>
    find.descendant(of: fieldWithId(id), matching: find.text(message));

ProgrammeScheduleData _scheduleOf(Map<String, dynamic> values) =>
    values[ProgrammeScheduleAdjustFormFields.scheduleId]
        as ProgrammeScheduleData;

void main() {
  group('Issue 61: ProgrammeScheduleAdjustForm values', () {
    testWidgets('Issue 61: validate returns exactly From, the schedule and '
        'the venue id, typed', (tester) async {
      final state = await mountAdjustForm(tester);

      final values = state.validate()!;

      expect(values.keys, [
        ProgrammeScheduleAdjustFormFields.fromId,
        ProgrammeScheduleAdjustFormFields.scheduleId,
        ProgrammeScheduleAdjustFormFields.venueId,
      ]);
      expect(values[ProgrammeScheduleAdjustFormFields.fromId], isA<DateTime>());
      expect(
        values[ProgrammeScheduleAdjustFormFields.scheduleId],
        isA<ProgrammeScheduleData>(),
      );
      expect(values[ProgrammeScheduleAdjustFormFields.venueId], isA<int>());
      expect(state.currentValue, adjustInitial);
    });

    testWidgets('Issue 61: terms changed in the fields are what validate '
        'returns, with the dates left as seeded', (tester) async {
      final state = await mountAdjustForm(tester);

      await tester.tap(find.byType(WeekdayChip).at(2));
      await tester.pumpAndSettle();
      await enterStartTime(tester, 18, 15);
      await enterDuration(tester, '1h 30m');
      await pickOption(tester, 'North Rink', 'Hall');
      await pickOption(
        tester,
        shownFrom(adjustFromOptions.first),
        shownFrom(adjustFromOptions[1]),
      );

      expect(state.validate(), {
        ProgrammeScheduleAdjustFormFields.fromId: adjustFromOptions[1],
        ProgrammeScheduleAdjustFormFields.scheduleId: ProgrammeScheduleData(
          weekdays: const {
            DateTime.monday,
            DateTime.wednesday,
            DateTime.thursday,
          },
          startDate: DateTime(2030, 5),
          sessionStartTime: const ShadTimeOfDay(
            hour: 18,
            minute: 15,
            second: 0,
          ),
          totalDurationMinutes: 90,
        ),
        ProgrammeScheduleAdjustFormFields.venueId: 9,
      });
    });

    testWidgets('Issue 61: a split made in the Sessions editor comes back in '
        'the schedule', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: adjustInitial.copyWith(
          schedule: adjustSchedule.copyWith(totalDurationMinutes: 120),
        ),
      );

      await pickHour(tester, 0, 1);
      await tester.enterText(find.byType(EditableText).last, ' Game ');
      await tester.pumpAndSettle();

      expect(_scheduleOf(state.validate()!).sessions, const [
        SessionInput(name: 'Session 1', startTime: '12:00', endTime: '13:00'),
        SessionInput(name: 'Game', startTime: '13:00', endTime: '14:00'),
      ]);
    });

    testWidgets('Issue 61: a seeded split comes back unchanged', (
      tester,
    ) async {
      const sessions = [
        SessionInput(name: 'Off-ice', startTime: '12:00', endTime: '12:30'),
        SessionInput(name: 'On-ice', startTime: '12:30', endTime: '13:30'),
      ];
      final seeded = adjustInitial.copyWith(
        schedule: adjustSchedule.copyWith(
          totalDurationMinutes: 90,
          sessions: sessions,
        ),
      );
      final state = await mountAdjustForm(tester, initialValue: seeded);

      expect(state.isDirty, isFalse);
      expect(_scheduleOf(state.validate()!), seeded.schedule);
      expect(shownDurations(tester), ['0:30', '1:00']);
    });
  });

  group('Issue 61: ProgrammeScheduleAdjustForm dirty check', () {
    testWidgets('Issue 61: a tapped weekday makes the form dirty, and '
        'tapping it off makes it clean', (tester) async {
      final state = await mountAdjustForm(tester);
      expect(state.isDirty, isFalse);

      await tester.tap(find.byType(WeekdayChip).at(1));
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(find.byType(WeekdayChip).at(1));
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another venue makes the form dirty, and the old '
        'one makes it clean', (tester) async {
      final state = await mountAdjustForm(tester);

      await pickOption(tester, 'North Rink', 'Hall');
      expect(state.isDirty, isTrue);

      await pickOption(tester, 'Hall', 'North Rink');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another duration makes the form dirty, and the '
        'old one makes it clean', (tester) async {
      final state = await mountAdjustForm(tester);

      await enterDuration(tester, '90m');
      expect(state.isDirty, isTrue);

      await enterDuration(tester, '1h');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another start time makes the form dirty, and the '
        'old one makes it clean', (tester) async {
      final state = await mountAdjustForm(tester);

      await enterStartTime(tester, 7);
      expect(state.isDirty, isTrue);

      await enterStartTime(tester, 12);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a split makes the form dirty, and removing it '
        'makes it clean', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: adjustInitial.copyWith(
          schedule: adjustSchedule.copyWith(totalDurationMinutes: 120),
        ),
      );

      await pickHour(tester, 0, 1);
      expect(state.isDirty, isTrue);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });
  });

  group('Issue 61: ProgrammeScheduleAdjustForm contract', () {
    testWidgets('Issue 61: a refusal shows on From, the schedule or Venue, '
        'and inline; the form validates again afterwards', (tester) async {
      final state = await mountAdjustForm(tester);

      for (final id in [
        ProgrammeScheduleAdjustFormFields.fromId,
        ProgrammeScheduleAdjustFormFields.scheduleId,
        ProgrammeScheduleAdjustFormFields.venueId,
      ]) {
        await expectShowsServerErrors(tester, state, id);
      }

      state.showErrors(
        fieldErrors: const {
          ProgrammeScheduleAdjustFormFields.scheduleId: 'Clashes with U12.',
        },
        formError: 'Could not save.',
      );
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeScheduleAdjustFormFields.scheduleId,
          'Clashes with U12.',
        ),
        findsOneWidget,
      );
      expect(find.text('Could not save.'), findsOneWidget);

      expect(state.validate(), {
        ProgrammeScheduleAdjustFormFields.fromId: adjustInitial.from,
        ProgrammeScheduleAdjustFormFields.scheduleId: adjustInitial.schedule,
        ProgrammeScheduleAdjustFormFields.venueId: adjustInitial.venueId,
      });
      await tester.pumpAndSettle();
      expect(find.text('Clashes with U12.'), findsNothing);
      expect(find.text('Could not save.'), findsNothing);
    });

    testWidgets('Issue 61: disabled, no picker opens, no weekday toggles and '
        'no input takes text', (tester) async {
      final state = await mountAdjustForm(tester, enabled: false);

      await tester.tap(
        find.text(shownFrom(adjustFromOptions.first)),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text(shownFrom(adjustFromOptions[1])), findsNothing);

      await tester.tap(find.text('North Rink'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Hall'), findsNothing);

      await tester.tap(find.byType(WeekdayChip).at(1), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1:00'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expectInputsDisabled(tester);
      expect(
        tester.widget<ShadTimePicker>(find.byType(ShadTimePicker)).enabled,
        isFalse,
      );
      expect(state.isDirty, isFalse);
      expect(state.currentValue, adjustInitial);
    });

    testWidgets('Issue 61: the form fits a phone, with a split', (
      tester,
    ) async {
      await expectFitsPhone(
        tester,
        ProgrammeScheduleAdjustForm(
          initialValue: adjustInitial.copyWith(
            schedule: adjustSchedule.copyWith(
              totalDurationMinutes: 90,
              sessions: const [
                SessionInput(
                  name: 'Off-ice warm-up',
                  startTime: '12:00',
                  endTime: '12:30',
                ),
                SessionInput(
                  name: 'On-ice',
                  startTime: '12:30',
                  endTime: '13:30',
                ),
              ],
            ),
          ),
          fromOptions: adjustFromOptions,
          venues: adjustVenues,
        ),
      );
      expect(rowLabels(tester), hasLength(6));
    });

    testWidgets('Issue 61: the form has no heading and no button', (
      tester,
    ) async {
      await mountAdjustForm(tester);

      // Without the date range the schedule cluster has no Clear button.
      expectNoHostChrome(tester);
      expect(find.byType(ShadButton), findsNothing);
    });
  });
}
