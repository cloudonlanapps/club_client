// CampScheduleForm against the form contract (issue 61), second part: the
// dirty check, server errors, the disabled form and the phone width. The
// fields, validation and values are in camp_schedule_form_contract_test.dart.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/form_harness.dart';

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
  group('CampScheduleForm dirty check', () {
    testWidgets('Issue 61: a text input dirties the form, typing the seeded '
        'value back cleans it', (tester) async {
      final state = await _pump(tester, _seed());
      expect(state.isDirty, isFalse);

      await typeInRow(tester, 'Training Days', '6');
      expect(state.isDirty, isTrue);
      await typeInRow(tester, 'Training Days', '5');
      expect(state.isDirty, isFalse);

      await typeInRow(tester, 'Duration', '3h');
      expect(state.isDirty, isTrue);
      await typeInRow(tester, 'Duration', '2h');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the date and the start time dirty the form and '
        'clean it when put back', (tester) async {
      final state = await _pump(tester, _seed());

      await pickScheduleDate(tester, DateTime(2026, 8, 10));
      expect(state.isDirty, isTrue);
      await pickScheduleDate(tester, DateTime(2026, 8, 3));
      expect(state.isDirty, isFalse);

      await pickScheduleStartTime(tester, timeAt(7));
      expect(state.isDirty, isTrue);
      await pickScheduleStartTime(tester, timeAt(6));
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a rest day dirties the form, tapping it again '
        'cleans it', (tester) async {
      final state = await _pump(tester, _seed());

      await tapRestDay(tester, 5);
      expect(state.isDirty, isTrue);
      expect(_valueOf(state.validate()).excludedDates, {DateTime(2026, 8, 5)});

      await tapRestDay(tester, 5);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a split dirties the form, removing it cleans it', (
      tester,
    ) async {
      final state = await _pump(tester, _seed());

      _body(tester).onSessionDurationChanged(0, const Duration(minutes: 30));
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(find.byIcon(LucideIcons.x).first);
      await tester.pumpAndSettle();
      expect(_body(tester).sessionDurations, [120]);
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: renaming a session of a seeded split dirties the '
        'form', (tester) async {
      final state = await _pump(tester, _seed(sessions: _split));
      expect(state.isDirty, isFalse);

      await typeInRow(tester, 'Sessions', 'Dryland');
      expect(state.isDirty, isTrue);
      await typeInRow(tester, 'Sessions', 'Off-Ice');
      expect(state.isDirty, isFalse);
    });
  });

  group('CampScheduleForm server errors', () {
    testWidgets('Issue 61: a refusal shows on the schedule or inline, and '
        'the form saves again afterwards', (tester) async {
      final initial = _seed();
      final state = await _pump(tester, initial);

      await expectShowsServerErrors(tester, state, _id);

      state.showErrors(
        fieldErrors: const {_id: 'Overlaps another camp.'},
        formError: 'Could not save.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Overlaps another camp.'), findsOneWidget);
      expect(find.text('Could not save.'), findsOneWidget);

      expect(state.validate(), {_id: initial});
      await tester.pumpAndSettle();
      expect(find.text('Overlaps another camp.'), findsNothing);
      expect(find.text('Could not save.'), findsNothing);
    });

    testWidgets('Issue 61: a refusal for a field the form does not have '
        'shows inline', (tester) async {
      final state = await _pump(tester, _seed());

      state.showErrors(fieldErrors: const {'venue': 'Venue is closed.'});
      await tester.pumpAndSettle();

      expect(find.text('Venue is closed.'), findsOneWidget);
    });
  });

  group('CampScheduleForm disabled', () {
    testWidgets('Issue 61: with enabled false no input responds', (
      tester,
    ) async {
      final initial = _seed(
        excludedDates: {DateTime(2026, 8, 5)},
        sessions: _split,
      );
      final state = await _pump(tester, initial, enabled: false);

      for (final input in tester.widgetList<ShadInputFormField>(
        find.byType(ShadInputFormField),
      )) {
        expect(input.enabled, isFalse);
      }
      for (final input in tester.widgetList<ShadInput>(
        find.byType(ShadInput),
      )) {
        expect(input.enabled, isFalse);
      }
      expect(
        tester
            .widget<ShadTimePickerFormField>(
              find.byType(ShadTimePickerFormField),
            )
            .enabled,
        isFalse,
      );

      // The date picker does not open.
      await tester.tap(
        find.byType(CLDatePickerFormField),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(scheduleDatePickerIsOpen(tester), isFalse);

      // A rest day does not toggle, on or off.
      await tapRestDay(tester, 5);
      await tapRestDay(tester, 6);
      // A session's length picker does not open, its remove button is dead.
      await tester.tap(find.byType(DurationPickerDropdown).first);
      await tester.tap(find.byIcon(LucideIcons.x).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerColumn), findsNothing);
      for (final button in tester.widgetList<IconButton>(
        find.descendant(
          of: scheduleRow('Sessions'),
          matching: find.byType(IconButton),
        ),
      )) {
        expect(button.onPressed, isNull);
      }

      expect(state.isDirty, isFalse);
      expect(state.validate(), {_id: initial});
    });

    testWidgets('Issue 61: the same taps change an enabled form', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        _seed(excludedDates: {DateTime(2026, 8, 5)}, sessions: _split),
      );

      await tapRestDay(tester, 6);
      expect(state.isDirty, isTrue);

      await tester.tap(find.byType(DurationPickerDropdown).first);
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerColumn), findsNWidgets(2));
    });

    testWidgets('Issue 61: the date picker of an enabled form opens', (
      tester,
    ) async {
      // A short month name: in the test font a long one overflows the
      // header of cl_calendar's popover, which is not this form's to fix.
      await _pump(
        tester,
        _seed().copyWith(startDate: () => DateTime(2026, 5, 4)),
      );

      await tester.tap(find.byType(CLDatePickerFormField));
      await tester.pumpAndSettle();

      expect(scheduleDatePickerIsOpen(tester), isTrue);
    });
  });

  group('CampScheduleForm at phone width', () {
    testWidgets('Issue 61: a full schedule fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        CampScheduleForm(
          initialValue: _seed(
            excludedDates: {DateTime(2026, 8, 5)},
            sessions: _split,
          ),
        ),
      );
      expect(find.text('Rest Days (tap to toggle)'), findsOneWidget);
    });

    testWidgets('Issue 61: the messages of an empty schedule fit a phone', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        const CampScheduleData(),
        size: kPhoneSurface,
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Start date is required'), findsWidgets);
    });
  });
}
