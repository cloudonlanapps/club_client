// The session split of the camp and the programme cluster against their
// Start Time: a split follows a start time that moves (issue 62), and a
// split made before there is a start time is kept and timed once one is set
// (issue 63).
import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/models/programme_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_schedule_cluster.dart';
import '../support/programme_timetable_support.dart';

const _campFieldId = 'schedule';

const ShadTimeOfDay _sevenAm = ShadTimeOfDay(hour: 7, minute: 0, second: 0);

/// Two hours from seven split as [kWarmUpAndDrills] is from six.
const List<SessionInput> _warmUpAndDrillsFromSeven = [
  SessionInput(name: 'Warm-up', startTime: '07:00', endTime: '07:30'),
  SessionInput(name: 'Drills', startTime: '07:30', endTime: '09:00'),
];

/// Two hours from seven split into two unnamed hours.
const List<SessionInput> _twoHoursFromSeven = [
  SessionInput(name: 'Session 1', startTime: '07:00', endTime: '08:00'),
  SessionInput(name: 'Session 2', startTime: '08:00', endTime: '09:00'),
];

Future<GlobalKey<ShadFormState>> _pumpCampField(
  WidgetTester tester,
  CampScheduleData initialValue,
) => pumpFieldInForm(
  tester,
  CampScheduleFormField(
    id: _campFieldId,
    initialValue: initialValue,
    validator: CampScheduleFormField.aggregateValidator,
  ),
);

CampScheduleData _campValue(GlobalKey<ShadFormState> form) =>
    form.currentState!.value[_campFieldId] as CampScheduleData;

void main() {
  group('Issue 63: SessionSplitField sessions for a start time', () {
    testWidgets('Issue 63: sessionsFrom lays the split out from the start '
        'it is given, and gives none without one', (tester) async {
      await pumpForm(
        tester,
        SessionSplitField(
          totalMinutes: 120,
          startTime: null,
          initialSessions: const [],
          onChanged: (_) {},
        ),
      );
      await pickHour(tester, 0, 1);
      final split = tester.state<SessionSplitFieldState>(
        find.byType(SessionSplitField),
      );

      expect(split.buildSessions(), isEmpty);
      expect(split.sessionsFrom(null), isEmpty);
      expect(split.sessionsFrom(_sevenAm), _twoHoursFromSeven);
    });

    testWidgets('Issue 63: sessionsFrom gives none for an undivided day', (
      tester,
    ) async {
      await pumpForm(
        tester,
        SessionSplitField(
          totalMinutes: 120,
          startTime: kSixAm,
          initialSessions: const [],
          onChanged: (_) {},
        ),
      );
      final split = tester.state<SessionSplitFieldState>(
        find.byType(SessionSplitField),
      );

      expect(split.sessionsFrom(_sevenAm), isEmpty);
    });
  });

  group('Issue 62: a split follows the start time', () {
    testWidgets('Issue 62: camp, a new start time moves the sessions and '
        'keeps their names and lengths', (tester) async {
      final form = await _pumpCampField(
        tester,
        CampScheduleData(
          startDate: DateTime(2030, 7),
          sessionStartTime: kSixAm,
          sessions: kWarmUpAndDrills,
        ),
      );

      await enterStartTime(tester, 7);

      expect(_campValue(form).sessionStartTime, _sevenAm);
      expect(_campValue(form).sessions, _warmUpAndDrillsFromSeven);
      expect(shownDurations(tester), ['0:30', '1:30']);
    });

    testWidgets('Issue 62: programme, a new start time moves the sessions '
        'and keeps their names and lengths', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(
          sessionStartTime: () => kSixAm,
          sessions: kWarmUpAndDrills,
        ),
      );

      await enterStartTime(tester, 7);

      expect(programmeValue(form).sessionStartTime, _sevenAm);
      expect(programmeValue(form).sessions, _warmUpAndDrillsFromSeven);
      expect(programmeValue(form).totalDurationMinutes, 120);
    });
  });

  group('Issue 63: a split made before the start time is kept', () {
    testWidgets('Issue 63: camp, a split made with no start time takes its '
        'times when the start time is set', (tester) async {
      final form = await _pumpCampField(
        tester,
        CampScheduleData(startDate: DateTime(2030, 7)),
      );

      await pickHour(tester, 0, 1);
      expect(_campValue(form).sessions, isEmpty);
      await enterStartTime(tester, 7);

      expect(_campValue(form).sessions, _twoHoursFromSeven);
      expect(shownDurations(tester), ['1:00', '1:00']);
      expect(form.currentState!.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 63: programme, a split made with no start time takes '
        'its times when the start time is set', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: ProgrammeScheduleData(
          weekdays: const {DateTime.monday},
          startDate: DateTime(2030, 5, 6),
          totalDurationMinutes: 120,
        ),
      );

      await pickHour(tester, 0, 1);
      expect(programmeValue(form).sessions, isEmpty);
      await enterStartTime(tester, 7);

      expect(programmeValue(form).sessions, _twoHoursFromSeven);
      expect(await validateProgramme(tester, form), isTrue);
    });
  });
}
