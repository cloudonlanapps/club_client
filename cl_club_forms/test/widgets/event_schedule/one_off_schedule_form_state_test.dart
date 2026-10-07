// OneOffScheduleForm against the form contract (issue 61), second part: the
// dirty check, server errors, the disabled form and the phone width. The
// fields, validation, postpone-only rule and values are in
// one_off_schedule_form_contract_test.dart.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/camp_one_off_schedule_helpers.dart';
import '../../support/form_harness.dart';

const String _scheduleId = OneOffScheduleFormFields.scheduleId;
const String _venueId = OneOffScheduleFormFields.venueId;
const String _sessionsId = OneOffScheduleFormFields.sessionsId;

final _date = DateTime(2030, 5, 14);

const _venues = [
  EventVenueOption(id: 7, name: 'North Rink'),
  EventVenueOption(id: 9, name: 'Hall'),
];

const _split = [
  SessionInput(name: 'Warm-up', startTime: '18:00', endTime: '18:30'),
  SessionInput(name: 'Match', startTime: '18:30', endTime: '20:00'),
];

OneOffScheduleValue _initial({
  List<SessionInput> sessions = const [],
  int? venueId = 7,
}) => OneOffScheduleValue(
  schedule: OneOffScheduleData(date: _date, startTime: timeAt(18)),
  venueId: venueId,
  sessions: sessions,
);

Widget _form(
  OneOffScheduleValue initial, {
  DateTime? notBefore,
  bool enabled = true,
}) => OneOffScheduleForm(
  initialValue: initial,
  venues: _venues,
  notBefore: notBefore,
  enabled: enabled,
);

Future<OneOffScheduleFormState> _pump(
  WidgetTester tester,
  OneOffScheduleValue initial, {
  DateTime? notBefore,
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  await pumpForm(
    tester,
    _form(initial, notBefore: notBefore, enabled: enabled),
    size: size,
  );
  return tester.state<OneOffScheduleFormState>(find.byType(OneOffScheduleForm));
}

SessionSplitFieldState _splitState(WidgetTester tester) =>
    tester.state<SessionSplitFieldState>(find.byType(SessionSplitField));

Future<void> _chooseVenue(WidgetTester tester, String name) async {
  await tester.tap(
    find.descendant(
      of: fieldWithId(_venueId),
      matching: find.byType(ShadSelect<int>),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  group('OneOffScheduleForm dirty check', () {
    testWidgets('Issue 61: the duration text dirties the form, typing the '
        'seeded one back cleans it', (tester) async {
      final state = await _pump(tester, _initial());
      expect(state.isDirty, isFalse);

      await typeInRow(tester, 'Duration', '90m');
      expect(state.isDirty, isTrue);
      await typeInRow(tester, 'Duration', '2h');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the venue dirties the form, choosing the seeded '
        'one again cleans it', (tester) async {
      final state = await _pump(tester, _initial());

      await _chooseVenue(tester, 'Hall');
      expect(state.isDirty, isTrue);
      await _chooseVenue(tester, 'North Rink');
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the date and the start time dirty the form and '
        'clean it when put back', (tester) async {
      final state = await _pump(tester, _initial());

      await pickScheduleDate(tester, DateTime(2030, 5, 20));
      expect(state.isDirty, isTrue);
      await pickScheduleDate(tester, _date);
      expect(state.isDirty, isFalse);

      await pickScheduleStartTime(tester, timeAt(19));
      expect(state.isDirty, isTrue);
      await pickScheduleStartTime(tester, timeAt(18));
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a split dirties the form, removing it cleans it', (
      tester,
    ) async {
      final state = await _pump(tester, _initial());

      _splitState(tester).onSessionDurationChanged(
        0,
        const Duration(minutes: 30),
      );
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.tap(find.byIcon(LucideIcons.x).first);
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: a start time moved and moved back leaves a '
        'seeded split clean', (tester) async {
      final state = await _pump(tester, _initial(sessions: _split));

      await pickScheduleStartTime(tester, timeAt(19));
      expect(state.isDirty, isTrue);
      await pickScheduleStartTime(tester, timeAt(18));
      expect(state.isDirty, isFalse);
    });
  });

  group('OneOffScheduleForm server errors', () {
    testWidgets('Issue 61: a refusal shows on the venue or inline, and the '
        'form saves again afterwards', (tester) async {
      final initial = _initial(sessions: _split);
      final state = await _pump(tester, initial);

      await expectShowsServerErrors(tester, state, _venueId);

      state.showErrors(
        fieldErrors: const {_scheduleId: 'Clashes with another event.'},
        formError: OneOffScheduleFormValidators.postponeOnlyMessage,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(_scheduleId),
          matching: find.text('Clashes with another event.'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsOneWidget,
      );

      expect(state.validate(), {
        _scheduleId: initial.schedule,
        _venueId: 7,
        _sessionsId: _split,
      });
      await tester.pumpAndSettle();
      expect(find.text('Clashes with another event.'), findsNothing);
      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsNothing,
      );
    });

    testWidgets('Issue 61: a refusal for a field the form does not have '
        'shows inline', (tester) async {
      final state = await _pump(tester, _initial());

      state.showErrors(fieldErrors: const {'capacity': 'Too many.'});
      await tester.pumpAndSettle();

      expect(find.text('Too many.'), findsOneWidget);
    });
  });

  group('OneOffScheduleForm disabled', () {
    testWidgets('Issue 61: with enabled false no input responds', (
      tester,
    ) async {
      final initial = _initial(sessions: _split);
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

      // Neither the date picker nor the venue picker opens.
      await tester.tap(
        find.byType(CLDatePickerFormField),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(scheduleDatePickerIsOpen(tester), isFalse);
      await tester.tap(
        find.descendant(
          of: fieldWithId(_venueId),
          matching: find.byType(ShadSelect<int>),
        ),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Hall'), findsNothing);

      // A session's length picker does not open, its remove button is dead.
      await tester.tap(find.byType(DurationPickerDropdown).first);
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerColumn), findsNothing);
      for (final button in tester.widgetList<IconButton>(
        find.byType(IconButton),
      )) {
        expect(button.onPressed, isNull);
      }

      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: the same taps open the pickers of an enabled '
        'form', (tester) async {
      await _pump(tester, _initial(sessions: _split));

      await tester.tap(
        find.descendant(
          of: fieldWithId(_venueId),
          matching: find.byType(ShadSelect<int>),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hall'), findsOneWidget);
    });

    testWidgets('Issue 61: the date picker of an enabled form opens', (
      tester,
    ) async {
      await _pump(tester, _initial());

      await tester.tap(find.byType(CLDatePickerFormField));
      await tester.pumpAndSettle();

      expect(scheduleDatePickerIsOpen(tester), isTrue);
    });
  });

  group('OneOffScheduleForm at phone width', () {
    testWidgets('Issue 61: a split one-off fits a phone, its date, start '
        'time and duration stacked in one column', (tester) async {
      await expectFitsPhone(tester, _form(_initial(sessions: _split)));

      final time = tester.getTopLeft(scheduleRow('Start Time'));
      final duration = tester.getTopLeft(scheduleRow('Duration'));
      expect(duration.dx, time.dx);
      expect(duration.dy, greaterThan(time.dy));
    });

    testWidgets('Issue 61: on a wide surface the start time and duration '
        'share a row', (tester) async {
      await _pump(tester, _initial());

      final time = tester.getTopLeft(scheduleRow('Start Time'));
      final duration = tester.getTopLeft(scheduleRow('Duration'));
      expect(duration.dy, time.dy);
      expect(duration.dx, greaterThan(time.dx));
    });

    testWidgets('Issue 61: the messages of an empty form fit a phone', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        const OneOffScheduleValue(schedule: OneOffScheduleData()),
        size: kPhoneSurface,
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(OneOffScheduleFormValidators.venueRequiredMessage),
        findsOneWidget,
      );
    });
  });
}
