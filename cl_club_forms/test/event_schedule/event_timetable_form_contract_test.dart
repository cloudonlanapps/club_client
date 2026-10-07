// Points of issue 61 that do not apply to EventTimetableForm: it has no
// required field, nothing typed is trimmed (a session name is trimmed by the
// split editor, see session_split_field_test.dart) and no rule across
// fields. The Schedule picker is the only field a parameter hides.
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventTimetableForm,
        EventTimetableFormFields,
        EventTimetableFormState,
        EventTimetableFormValidators,
        SessionInput,
        TimetableScheduleOption;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const ShadTimeOfDay _six = ShadTimeOfDay(hour: 6, minute: 0, second: 0);

const List<SessionInput> _split = [
  SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:00'),
];

/// What the form returns for the schedule [scheduleId] split as [sessions].
Map<String, dynamic> _values(int scheduleId, List<SessionInput> sessions) => {
  EventTimetableFormFields.scheduleId: scheduleId,
  EventTimetableFormFields.sessionsId: sessions,
};

const TimetableScheduleOption _earlier = TimetableScheduleOption(
  id: 10,
  label: 'From 1 Jun 2026 until 1 Jul 2026',
  startTime: _six,
  totalMinutes: 90,
);

const TimetableScheduleOption _current = TimetableScheduleOption(
  id: 11,
  label: 'From 1 Jul 2026 (current)',
  startTime: _six,
  totalMinutes: 120,
  sessions: _split,
);

/// Mounts the form through the shared harness and returns its state.
Future<EventTimetableFormState> _mount(
  WidgetTester tester, {
  List<TimetableScheduleOption> schedules = const [_current],
  int? initialScheduleIndex,
  String? note,
  bool enabled = true,
}) async {
  final key = GlobalKey<EventTimetableFormState>();
  await pumpForm(
    tester,
    EventTimetableForm(
      key: key,
      schedules: schedules,
      initialScheduleIndex: initialScheduleIndex,
      note: note,
      enabled: enabled,
    ),
  );
  return key.currentState!;
}

List<String> _sessionNames(WidgetTester tester) => [
  for (final input in tester.widgetList<ShadInput>(find.byType(ShadInput)))
    input.controller!.text,
];

void main() {
  group('Issue 61: EventTimetableForm fields', () {
    testWidgets('Issue 61: one schedule shows the Sessions row alone', (
      tester,
    ) async {
      await _mount(tester);

      expect(rowLabels(tester), ['Sessions']);
      expectLabelsAreRows(tester);
      expect(fieldWithId(EventTimetableFormFields.scheduleId), findsNothing);
      expect(_sessionNames(tester), ['Warm-up', 'Drills']);
    });

    testWidgets('Issue 61: several schedules add the Schedule picker above '
        'Sessions, neither marked required', (tester) async {
      await _mount(tester, schedules: const [_earlier, _current]);

      expect(rowLabels(tester), ['Schedule', 'Sessions']);
      expectLabelsAreRows(tester);
      expect(fieldWithId(EventTimetableFormFields.scheduleId), findsOneWidget);
    });

    testWidgets('Issue 61: the note shows only when the host gives one', (
      tester,
    ) async {
      await _mount(tester, note: 'No dates move.');
      expect(find.text('No dates move.'), findsOneWidget);

      await _mount(tester);
      expect(find.text('No dates move.'), findsNothing);
    });

    testWidgets('Issue 61: the form opens on the schedule the host names', (
      tester,
    ) async {
      final state = await _mount(
        tester,
        schedules: const [_earlier, _current],
        initialScheduleIndex: 0,
      );

      expect(state.selectedSchedule, _earlier);
      expect(find.text(_earlier.label), findsOneWidget);
      expect(_sessionNames(tester), ['']);
      expect(shownDurations(tester), ['1:30']);
      expect(state.validate(), _values(10, const []));
    });

    testWidgets('Issue 61: picking another schedule in the picker shows its '
        'own split over its own length', (tester) async {
      final state = await _mount(tester, schedules: const [_earlier, _current]);
      expect(shownDurations(tester), ['0:30', '1:30']);

      await tester.tap(find.text(_current.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_earlier.label));
      await tester.pumpAndSettle();

      expect(state.selectedSchedule, _earlier);
      expect(shownDurations(tester), ['1:30']);
      expect(_sessionNames(tester), ['']);
      expect(state.isDirty, isFalse);

      // Split the earlier schedule's hour and a half: the edit is its own.
      await pickMinute(tester, 0, 0);
      expect(state.isDirty, isTrue);
      expect(
        state.validate(),
        _values(10, const [
          SessionInput(name: 'Session 1', startTime: '06:00', endTime: '07:00'),
          SessionInput(name: 'Session 2', startTime: '07:00', endTime: '07:30'),
        ]),
      );
    });
  });

  group('Issue 61: EventTimetableForm values', () {
    testWidgets('Issue 61: validate returns exactly the schedule id and the '
        'split, typed', (tester) async {
      final state = await _mount(tester);

      final values = state.validate()!;

      expect(values.keys, [
        EventTimetableFormFields.scheduleId,
        EventTimetableFormFields.sessionsId,
      ]);
      expect(values[EventTimetableFormFields.scheduleId], isA<int>());
      expect(
        values[EventTimetableFormFields.sessionsId],
        isA<List<SessionInput>>(),
      );
    });

    testWidgets('Issue 61: a schedule without an id comes back with a null '
        'id and an empty split', (tester) async {
      final state = await _mount(
        tester,
        schedules: const [
          TimetableScheduleOption(
            label: 'the camp',
            startTime: _six,
            totalMinutes: 120,
          ),
        ],
      );

      expect(state.validate(), {
        EventTimetableFormFields.scheduleId: null,
        EventTimetableFormFields.sessionsId: const <SessionInput>[],
      });
    });

    testWidgets('Issue 61: a split made in the editor is what validate '
        'returns', (tester) async {
      final state = await _mount(tester);

      // Drills: 1:30 -> 0:30; the freed hour becomes a third session.
      await pickHour(tester, 1, 0);
      await tester.enterText(find.byType(EditableText).last, ' Game ');
      await tester.pumpAndSettle();

      expect(
        state.validate(),
        _values(11, const [
          SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
          SessionInput(name: 'Drills', startTime: '06:30', endTime: '07:00'),
          SessionInput(name: 'Game', startTime: '07:00', endTime: '08:00'),
        ]),
      );
      expect(state.currentSessions, hasLength(3));
    });
  });

  group('Issue 61: EventTimetableForm validation', () {
    testWidgets('Issue 61: a split that does not fill the day is refused on '
        'the Sessions field, and accepted once it does', (tester) async {
      final state = await _mount(
        tester,
        schedules: const [
          TimetableScheduleOption(
            id: 11,
            label: 'current',
            startTime: _six,
            totalMinutes: 150,
            sessions: _split,
          ),
        ],
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(EventTimetableFormFields.sessionsId),
          matching: find.text(
            EventTimetableFormValidators.totalMismatchMessage,
          ),
        ),
        findsOneWidget,
      );

      const filled = [
        SessionInput(name: 'Warm-up', startTime: '06:00', endTime: '06:30'),
        SessionInput(name: 'Drills', startTime: '06:30', endTime: '08:30'),
      ];
      await setField(
        tester,
        state,
        EventTimetableFormFields.sessionsId,
        filled,
      );
      expect(state.validate(), _values(11, filled));
      await tester.pumpAndSettle();
      expect(
        find.text(EventTimetableFormValidators.totalMismatchMessage),
        findsNothing,
      );
    });

    testWidgets('Issue 61: each schedule is checked against its own length', (
      tester,
    ) async {
      final state = await _mount(tester, schedules: const [_earlier, _current]);

      // The two-hour split is right for the current schedule, wrong for the
      // earlier one, an hour and a half long.
      expect(state.validate(), _values(11, _split));
      await setField(tester, state, EventTimetableFormFields.scheduleId, 0);
      await setField(
        tester,
        state,
        EventTimetableFormFields.sessionsId,
        _split,
      );
      expect(state.validate(), isNull);
    });
  });

  group('Issue 61: EventTimetableForm dirty check', () {
    testWidgets('Issue 61: renaming a session makes the form dirty, and the '
        'old name makes it clean again', (tester) async {
      final state = await _mount(tester);
      expect(state.isDirty, isFalse);

      await tester.enterText(find.byType(EditableText).first, 'Stretch');
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);

      await tester.enterText(find.byType(EditableText).first, 'Warm-up');
      await tester.pumpAndSettle();
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: removing a session makes the form dirty, and the '
        'seeded split put back makes it clean', (tester) async {
      final state = await _mount(tester);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(state.isDirty, isTrue);
      expect(state.currentSessions, isEmpty);

      await setField(
        tester,
        state,
        EventTimetableFormFields.sessionsId,
        List<SessionInput>.of(_split),
      );
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 61: another schedule alone is not a change, and an '
        'edit is measured against the schedule shown', (tester) async {
      final state = await _mount(tester, schedules: const [_earlier, _current]);

      await setField(tester, state, EventTimetableFormFields.scheduleId, 0);
      expect(state.isDirty, isFalse);

      await setField(
        tester,
        state,
        EventTimetableFormFields.sessionsId,
        const [
          SessionInput(name: 'A', startTime: '06:00', endTime: '07:00'),
          SessionInput(name: 'B', startTime: '07:00', endTime: '07:30'),
        ],
      );
      expect(state.isDirty, isTrue);

      // Back on the current schedule its own split shows, unedited.
      await setField(tester, state, EventTimetableFormFields.scheduleId, 1);
      expect(state.isDirty, isFalse);
      expect(state.validate(), _values(11, _split));
    });
  });

  group('Issue 61: EventTimetableForm contract', () {
    testWidgets('Issue 61: a refusal shows on Sessions and inline, and the '
        'form validates again afterwards', (tester) async {
      final state = await _mount(tester);

      await expectShowsServerErrors(
        tester,
        state,
        EventTimetableFormFields.sessionsId,
      );

      state.showErrors(
        fieldErrors: const {EventTimetableFormFields.sessionsId: 'Refused.'},
        formError: 'Could not save.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Refused.'), findsOneWidget);
      expect(find.text('Could not save.'), findsOneWidget);

      expect(state.validate(), _values(11, _split));
      await tester.pumpAndSettle();
      expect(find.text('Refused.'), findsNothing);
      expect(find.text('Could not save.'), findsNothing);
    });

    testWidgets('Issue 61: a refusal about the hidden Schedule picker shows '
        'inline', (tester) async {
      final state = await _mount(tester);

      state.showErrors(
        fieldErrors: const {
          EventTimetableFormFields.scheduleId: 'That schedule is gone.',
        },
      );
      await tester.pumpAndSettle();

      expect(find.text('That schedule is gone.'), findsOneWidget);
    });

    testWidgets('Issue 61: disabled, neither the picker nor the editor '
        'responds', (tester) async {
      final state = await _mount(
        tester,
        schedules: const [_earlier, _current],
        enabled: false,
      );

      await tester.tap(find.text(_current.label), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text(_earlier.label), findsNothing);

      await tester.tap(find.text('1:30'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(shownDurations(tester), ['0:30', '1:30']);
      await tester.tap(find.byType(IconButton).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      for (final input in tester.widgetList<ShadInput>(
        find.byType(ShadInput),
      )) {
        expect(input.enabled, isFalse);
      }

      expect(state.isDirty, isFalse);
      expect(state.selectedSchedule, _current);
      expect(state.currentSessions, _split);
    });

    testWidgets('Issue 61: the form fits a phone', (tester) async {
      await expectFitsPhone(
        tester,
        EventTimetableForm(
          schedules: const [_earlier, _current],
          note:
              'Corrects the timetable of every session of this schedule; '
              'no dates move.',
        ),
      );
      expect(rowLabels(tester), ['Schedule', 'Sessions']);
    });

    testWidgets('Issue 61: the form has no heading and no button of its own', (
      tester,
    ) async {
      await _mount(tester, schedules: const [_earlier, _current]);

      // The only buttons are the split editor's remove icons.
      expectNoHostChrome(tester);
      expect(find.byType(IconButton), findsNWidgets(2));
    });
  });
}
