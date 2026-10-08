// OneOffScheduleForm against the form contract (issue 61).
//
// Not applicable: no parameter hides or locks a field (`notBefore` only
// feeds the postpone-only rule). In-form actions: a split session's remove
// button (an icon button, no text).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/event_venue_select_field.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/camp_one_off_schedule_helpers.dart';
import '../../support/form_harness.dart';
import '../../support/programme_timetable_support.dart';

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
  group('OneOffScheduleForm fields', () {
    testWidgets('Issue 61: every input is a labelled row, the required ones '
        'marked', (tester) async {
      await _pump(tester, _initial());

      expect(rowLabels(tester), [
        'Date *',
        'Start Time *',
        'Duration *',
        'Venue *',
        'Sessions',
      ]);
      expectLabelsAreRows(tester);
    });

    testWidgets('Issue 61: with no venue chosen the picker shows its '
        'placeholder', (tester) async {
      await _pump(tester, _initial(venueId: null));

      expect(
        find.descendant(
          of: fieldWithId(_venueId),
          matching: find.text(EventVenueSelectField.placeholder),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: the form draws no button of the host', (
      tester,
    ) async {
      await _pump(tester, _initial(sessions: _split));

      expectNoHostChrome(tester);
      // Its only buttons are in-form: one remove button per split session.
      expect(find.byType(IconButton), findsNWidgets(2));
    });
  });

  group('OneOffScheduleForm field validation', () {
    testWidgets('Issue 61: a missing date is refused on its row', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        OneOffScheduleValue(
          schedule: OneOffScheduleData(startTime: timeAt(18)),
          venueId: 7,
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(textInRow('Date', 'Date is required'), findsOneWidget);

      await pickScheduleDate(tester, _date);
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: a missing start time is refused on its row', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        OneOffScheduleValue(
          schedule: OneOffScheduleData(date: _date),
          venueId: 7,
        ),
      );

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        textInRow('Start Time', 'Start time is required'),
        findsOneWidget,
      );

      await pickScheduleStartTime(tester, timeAt(18));
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: no venue is refused on the venue field, a chosen '
        'one accepted', (tester) async {
      final state = await _pump(tester, _initial(venueId: null));

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(_venueId),
          matching: find.text(
            OneOffScheduleFormValidators.venueRequiredMessage,
          ),
        ),
        findsOneWidget,
      );

      await _chooseVenue(tester, 'Hall');
      expect(state.validate()![_venueId], 9);
    });

    testWidgets('Issue 61: sessions that do not add up to the duration are '
        'refused on the sessions field', (tester) async {
      final state = await _pump(tester, _initial());

      await setField(tester, state, _sessionsId, const [
        SessionInput(name: 'Warm-up', startTime: '18:00', endTime: '18:30'),
        SessionInput(name: 'Match', startTime: '18:30', endTime: '19:00'),
      ]);
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: fieldWithId(_sessionsId),
          matching: find.text(
            EventTimetableFormValidators.totalMismatchMessage,
          ),
        ),
        findsOneWidget,
      );

      await setField(tester, state, _sessionsId, _split);
      expect(state.validate()![_sessionsId], _split);
    });
  });

  group('OneOffScheduleForm postpone-only rule', () {
    testWidgets('Issue 61: a start one minute before the present one is '
        'refused inline', (tester) async {
      final state = await _pump(
        tester,
        _initial(),
        notBefore: DateTime(2030, 5, 14, 18),
      );

      await pickScheduleStartTime(tester, timeAt(17, 59));
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: the present start itself is accepted', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        _initial(),
        notBefore: DateTime(2030, 5, 14, 18),
      );

      expect(state.validate(), isNotNull);
      await tester.pumpAndSettle();
      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsNothing,
      );
    });

    testWidgets('Issue 61: an earlier day is refused, and the message goes '
        'once the schedule is edited', (tester) async {
      final state = await _pump(
        tester,
        _initial(),
        notBefore: DateTime(2030, 5, 14, 18),
      );

      await pickScheduleDate(tester, DateTime(2030, 5, 13));
      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsOneWidget,
      );

      await pickScheduleDate(tester, DateTime(2030, 5, 15));
      expect(
        find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
        findsNothing,
      );
      expect(state.validate(), isNotNull);
    });

    testWidgets('Issue 61: with no present start any start is accepted', (
      tester,
    ) async {
      final state = await _pump(tester, _initial());

      await pickScheduleDate(tester, DateTime(2001));
      expect(state.validate(), isNotNull);
    });
  });

  group('OneOffScheduleForm values', () {
    testWidgets('Issue 61: validate returns exactly the three keys with '
        'their types', (tester) async {
      final initial = _initial(sessions: _split);
      final state = await _pump(tester, initial);

      final values = state.validate()!;

      expect(values.keys, [_scheduleId, _venueId, _sessionsId]);
      expect(values[_scheduleId], isA<OneOffScheduleData>());
      expect(values[_venueId], isA<int>());
      expect(values[_sessionsId], isA<List<SessionInput>>());
      expect(values[_scheduleId], initial.schedule);
      expect(values[_venueId], 7);
      expect(values[_sessionsId], _split);
    });

    testWidgets('Issue 61: an undivided one-off comes back with an empty '
        'sessions list', (tester) async {
      final state = await _pump(tester, _initial());

      final sessions = state.validate()![_sessionsId];

      expect(sessions, isA<List<SessionInput>>());
      expect(sessions, isEmpty);
    });

    testWidgets('Issue 61: what the user enters comes back assembled', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        const OneOffScheduleValue(schedule: OneOffScheduleData()),
      );

      await pickScheduleDate(tester, DateTime(2030, 6, 2));
      await pickScheduleStartTime(tester, timeAt(9, 30));
      await pickDuration(tester, 1, 30);
      await _chooseVenue(tester, 'North Rink');
      _splitState(tester).onSessionDurationChanged(
        0,
        const Duration(minutes: 30),
      );
      await tester.pumpAndSettle();
      await typeInRow(tester, 'Sessions', '  Briefing ');

      expect(state.validate(), {
        _scheduleId: OneOffScheduleData(
          date: DateTime(2030, 6, 2),
          startTime: timeAt(9, 30),
          durationMinutes: 90,
        ),
        _venueId: 7,
        _sessionsId: const [
          SessionInput(name: 'Briefing', startTime: '09:30', endTime: '10:00'),
          SessionInput(name: 'Session 2', startTime: '10:00', endTime: '11:00'),
        ],
      });
    });

    testWidgets('Issue 61: typing a new duration resets the split, a new '
        'start time moves it', (tester) async {
      final state = await _pump(tester, _initial(sessions: _split));

      await pickScheduleStartTime(tester, timeAt(10));
      expect(state.validate()![_sessionsId], const [
        SessionInput(name: 'Warm-up', startTime: '10:00', endTime: '10:30'),
        SessionInput(name: 'Match', startTime: '10:30', endTime: '12:00'),
      ]);

      await pickDuration(tester, 3);
      final values = state.validate()!;
      expect(values[_sessionsId], isEmpty);
      expect(
        (values[_scheduleId] as OneOffScheduleData).durationMinutes,
        180,
      );
      expect(_splitState(tester).sessionDurations, [180]);
    });
  });
}
