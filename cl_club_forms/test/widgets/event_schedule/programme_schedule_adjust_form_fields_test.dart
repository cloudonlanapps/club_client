// Points of issue 61 that do not apply to ProgrammeScheduleAdjustForm: it has
// no rule across fields of its own (the schedule cluster's aggregate
// validator is the nearest, tested here and in the cluster's own tests),
// nothing typed is trimmed, and no parameter hides or locks a field (the
// form always mounts the schedule cluster without its date range).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/event_venue_select_field.dart'
    show EventVenueSelectField;
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_adjust_form_validators.dart'
    show ProgrammeScheduleAdjustFormValidators;
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart'
    show WeekdayChip;
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
  group('Issue 61: ProgrammeScheduleAdjustForm fields', () {
    testWidgets('Issue 61: its rows are From, the schedule terms and Venue, '
        'in that order, with Sessions the only optional one', (tester) async {
      await mountAdjustForm(tester);

      expect(rowLabels(tester), [
        'From *',
        'Days of Week *',
        'Start Time *',
        'Duration *',
        'Sessions',
        'Venue *',
      ]);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: From offers every upcoming session, and the one '
        'picked is named in the effect line', (tester) async {
      final state = await mountAdjustForm(tester);
      expect(
        find.text(
          ProgrammeScheduleAdjustForm.effectLine(adjustFromOptions.first),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(shownFrom(adjustFromOptions.first)));
      await tester.pumpAndSettle();
      for (final option in adjustFromOptions) {
        expect(find.text(shownFrom(option)), findsWidgets);
      }
      await tester.tap(find.text(shownFrom(adjustFromOptions[2])).last);
      await tester.pumpAndSettle();

      expect(state.from, adjustFromOptions[2]);
      expect(state.currentValue.from, adjustFromOptions[2]);
      expect(
        find.text(ProgrammeScheduleAdjustForm.effectLine(adjustFromOptions[2])),
        findsOneWidget,
      );
      expect(
        find.text(
          ProgrammeScheduleAdjustForm.effectLine(adjustFromOptions.first),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 61: with no From yet the picker shows its placeholder '
        'and no effect line', (tester) async {
      await mountAdjustForm(
        tester,
        initialValue: ProgrammeScheduleAdjustValue(
          schedule: adjustSchedule,
          venueId: 7,
        ),
      );

      expect(find.text('Pick a session'), findsOneWidget);
      expect(find.textContaining('keep the present schedule'), findsNothing);
    });

    test('Issue 61: effectLine names the session in local time', () {
      expect(
        ProgrammeScheduleAdjustForm.effectLine(adjustFromOptions.first),
        'Sessions before ${shownFrom(adjustFromOptions.first)} keep the '
        'present schedule; sessions from it follow the new one.',
      );
    });
  });

  group('Issue 61: ProgrammeScheduleAdjustForm validation', () {
    testWidgets('Issue 61: no From is refused on From', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: ProgrammeScheduleAdjustValue(
          schedule: adjustSchedule,
          venueId: 7,
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeScheduleAdjustFormFields.fromId,
          ProgrammeScheduleAdjustFormValidators.fromRequiredMessage,
        ),
        findsOneWidget,
      );

      await setField(
        tester,
        state,
        ProgrammeScheduleAdjustFormFields.fromId,
        adjustFromOptions[1],
      );
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: a From that is not an upcoming session is refused '
        'on From', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: ProgrammeScheduleAdjustValue(
          from: DateTime.utc(2030, 5, 14, 6),
          schedule: adjustSchedule,
          venueId: 7,
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeScheduleAdjustFormFields.fromId,
          ProgrammeScheduleAdjustFormValidators.fromNotASessionMessage,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: no venue is refused on Venue', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: ProgrammeScheduleAdjustValue(
          from: adjustFromOptions.first,
          schedule: adjustSchedule,
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeScheduleAdjustFormFields.venueId,
          ProgrammeScheduleAdjustFormValidators.venueRequiredMessage,
        ),
        findsOneWidget,
      );

      await pickOption(tester, EventVenueSelectField.placeholder, 'Hall');
      expect(
        state.validate()?[ProgrammeScheduleAdjustFormFields.venueId],
        9,
      );
    });

    testWidgets('Issue 61: no weekday is refused, and one tapped day is '
        'accepted', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: adjustInitial.copyWith(
          schedule: adjustSchedule.copyWith(weekdays: const <int>{}),
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeScheduleAdjustFormFields.scheduleId,
          'Pick at least one day',
        ),
        findsWidgets,
      );

      await tester.tap(find.byType(WeekdayChip).at(5));
      await tester.pumpAndSettle();
      expect(_scheduleOf(state.validate()!).weekdays, {DateTime.saturday});
      await tester.pumpAndSettle();
      expect(find.text('Pick at least one day'), findsNothing);
    });

    testWidgets('Issue 61: no start time is refused', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: adjustInitial.copyWith(
          schedule: adjustSchedule.copyWith(sessionStartTime: () => null),
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        _onField(
          ProgrammeScheduleAdjustFormFields.scheduleId,
          'Start time is required',
        ),
        findsWidgets,
      );
    });

    testWidgets('Issue 61: a typed start time is accepted', (tester) async {
      final state = await mountAdjustForm(
        tester,
        initialValue: adjustInitial.copyWith(
          schedule: adjustSchedule.copyWith(sessionStartTime: () => null),
        ),
      );

      await enterStartTime(tester, 17, 30);

      expect(
        _scheduleOf(state.validate()!).sessionStartTime,
        const ShadTimeOfDay(hour: 17, minute: 30, second: 0),
      );
    });

    testWidgets('Issue 61: a duration of nothing is refused on Duration', (
      tester,
    ) async {
      final state = await mountAdjustForm(tester);

      for (final typed in ['0', '', 'soon']) {
        await enterDuration(tester, typed);
        expect(state.validate(), isNull, reason: 'typed "$typed"');
        await tester.pumpAndSettle();
        expect(find.text('Duration must be greater than 0'), findsOneWidget);
      }
    });

    testWidgets('Issue 61: a duration over four hours is refused', (
      tester,
    ) async {
      final state = await mountAdjustForm(tester);

      await enterDuration(tester, '4h 15m');

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(find.text('Programme session cannot exceed 4h'), findsWidgets);
    });

    testWidgets('Issue 61: a duration of four hours is accepted', (
      tester,
    ) async {
      final state = await mountAdjustForm(tester);

      await enterDuration(tester, '4h');

      expect(_scheduleOf(state.validate()!).totalDurationMinutes, 240);
      await tester.pumpAndSettle();
      expect(find.text('Programme session cannot exceed 4h'), findsNothing);
    });
  });
}
