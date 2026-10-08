// A session split that runs past midnight (issue 64): its times wrap to the
// next day, and what the form writes it reads back with the same lengths.
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/event_timetable_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const ShadTimeOfDay _elevenPm = ShadTimeOfDay(hour: 23, minute: 0, second: 0);

/// Two hours from eleven at night, an hour each.
const List<SessionInput> _acrossMidnight = [
  SessionInput(name: 'Session 1', startTime: '23:00', endTime: '00:00'),
  SessionInput(name: 'Session 2', startTime: '00:00', endTime: '01:00'),
];

void main() {
  group('Issue 64: session times past midnight', () {
    test('Issue 64: formatHM wraps to the next day', () {
      expect(SessionSplitField.formatHM(23 * 60 + 59), '23:59');
      expect(SessionSplitField.formatHM(24 * 60), '00:00');
      expect(SessionSplitField.formatHM(25 * 60 + 5), '01:05');
    });

    test('Issue 64: sessionMinutes reads an end before its start as the '
        'next day', () {
      expect(SessionSplitField.sessionMinutes(_acrossMidnight.first), 60);
      expect(
        SessionSplitField.sessionMinutes(
          const SessionInput(name: 'x', startTime: '23:30', endTime: '00:15'),
        ),
        45,
      );
      expect(SessionSplitField.sessionMinutes(_acrossMidnight.last), 60);
    });

    test('Issue 64: walkedFrom writes no hour above 23 and keeps the '
        'lengths', () {
      final walked = SessionSplitField.walkedFrom(
        kWarmUpAndDrills,
        const ShadTimeOfDay(hour: 23, minute: 45, second: 0),
      );

      expect(walked, const [
        SessionInput(name: 'Warm-up', startTime: '23:45', endTime: '00:15'),
        SessionInput(name: 'Drills', startTime: '00:15', endTime: '01:45'),
      ]);
      expect(
        [for (final s in walked) SessionSplitField.sessionMinutes(s)],
        [
          30,
          90,
        ],
      );
    });

    test('Issue 64: sessions across midnight add up to the occurrence', () {
      expect(
        EventTimetableFormValidators.sessionsTotal(_acrossMidnight, 120),
        isNull,
      );
    });

    testWidgets('Issue 64: a split from 23:00 is written wrapped', (
      tester,
    ) async {
      final emitted = <List<SessionInput>>[];
      await pumpForm(
        tester,
        SessionSplitField(
          totalMinutes: 120,
          startTime: _elevenPm,
          initialSessions: const [],
          onChanged: emitted.add,
        ),
      );

      await pickHour(tester, 0, 1);

      expect(emitted.last, _acrossMidnight);
    });

    testWidgets('Issue 64: a split across midnight is read back with its '
        'lengths', (tester) async {
      await pumpForm(
        tester,
        SessionSplitField(
          totalMinutes: 120,
          startTime: _elevenPm,
          initialSessions: _acrossMidnight,
          onChanged: (_) {},
        ),
      );

      expect(shownDurations(tester), ['1:00', '1:00']);
      expect(find.textContaining('unassigned'), findsNothing);
      expect(
        tester
            .state<SessionSplitFieldState>(find.byType(SessionSplitField))
            .buildSessions(),
        _acrossMidnight,
      );
    });
  });
}
