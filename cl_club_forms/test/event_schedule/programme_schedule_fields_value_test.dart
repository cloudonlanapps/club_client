// The value ProgrammeScheduleFormField builds from what is tapped, picked
// and typed, and `enabled: false`. Its rows, messages and the bounds of its
// aggregate validator are in programme_schedule_fields_contract_test.dart.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePicker;
import 'package:cl_club_forms/src/models/programme_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/programme_timetable_schedule_cluster.dart';
import '../support/programme_timetable_support.dart';

void main() {
  group('Issue 61: ProgrammeScheduleFormField value', () {
    testWidgets('Issue 61: a seeded value comes back unchanged', (
      tester,
    ) async {
      final seeded = validProgramme.copyWith(
        endDate: () => DateTime(2030, 9),
        hasNoEndDate: false,
        sessions: const [
          SessionInput(name: 'A', startTime: '09:00', endTime: '09:30'),
          SessionInput(name: 'B', startTime: '09:30', endTime: '11:00'),
        ],
      );
      final form = await pumpProgrammeField(tester, initialValue: seeded);

      expect(await validateProgramme(tester, form), isTrue);
      expect(programmeValue(form), seeded);
    });

    testWidgets('Issue 61: what is tapped, picked and typed into an empty '
        'cluster is the value', (tester) async {
      final form = await pumpProgrammeField(tester);

      await tester.tap(find.byType(WeekdayChip).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WeekdayChip).at(3));
      await tester.pumpAndSettle();
      await pickProgrammeDate(tester, 0, DateTime(2030, 5, 7));
      await pickProgrammeDate(tester, 1, DateTime(2030, 8, 29));
      await enterStartTime(tester, 16, 45);
      await enterDuration(tester, '1.5h');

      expect(await validateProgramme(tester, form), isTrue);
      expect(
        programmeValue(form),
        ProgrammeScheduleData(
          weekdays: const {DateTime.tuesday, DateTime.thursday},
          startDate: DateTime(2030, 5, 7),
          endDate: DateTime(2030, 8, 29),
          hasNoEndDate: false,
          sessionStartTime: const ShadTimeOfDay(
            hour: 16,
            minute: 45,
            second: 0,
          ),
          totalDurationMinutes: 90,
        ),
      );
    });

    testWidgets('Issue 61: the duration is read as hours, decimal hours, '
        'minutes, or both', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      for (final MapEntry(key: typed, value: minutes) in {
        '1h': 60,
        '1.5h': 90,
        '2': 120,
        '45m': 45,
        '1h 15m': 75,
        ' 3H ': 180,
      }.entries) {
        await enterDuration(tester, typed);
        expect(
          programmeValue(form).totalDurationMinutes,
          minutes,
          reason: '"$typed"',
        );
      }
    });

    testWidgets('Issue 61: a new duration drops the split and shows one '
        'session of the new length', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(
          sessions: const [
            SessionInput(name: 'A', startTime: '09:00', endTime: '09:30'),
            SessionInput(name: 'B', startTime: '09:30', endTime: '11:00'),
          ],
        ),
      );
      expect(shownDurations(tester), ['0:30', '1:30']);

      await enterDuration(tester, '1h');

      expect(shownDurations(tester), ['1:00']);
      expect(programmeValue(form).sessions, isEmpty);
      expect(programmeValue(form).totalDurationMinutes, 60);
    });

    testWidgets('Issue 61: a split made in the Sessions row starts at the '
        'start time', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      await pickHour(tester, 0, 1);

      expect(programmeValue(form).sessions, const [
        SessionInput(name: 'Session 1', startTime: '09:00', endTime: '10:00'),
        SessionInput(name: 'Session 2', startTime: '10:00', endTime: '11:00'),
      ]);
      expect(programmeValue(form).totalDurationMinutes, 120);
      expect(await validateProgramme(tester, form), isTrue);
    });

    testWidgets('Issue 61: seeded sessions set the duration shown', (
      tester,
    ) async {
      await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(
          totalDurationMinutes: 60,
          sessions: const [
            SessionInput(name: 'A', startTime: '09:00', endTime: '09:45'),
            SessionInput(name: 'B', startTime: '09:45', endTime: '10:30'),
          ],
        ),
      );

      expect(
        tester.widget<EditableText>(durationInput()).controller.text,
        '1h 30m',
      );
      expect(find.textContaining('unassigned'), findsNothing);
    });
  });

  group('Issue 61: ProgrammeScheduleFormField disabled', () {
    testWidgets('Issue 61: disabled, no day toggles, no date or length can '
        'be picked, nothing can be typed and Clear does nothing', (
      tester,
    ) async {
      final seeded = validProgramme.copyWith(
        endDate: () => DateTime(2030, 9),
        hasNoEndDate: false,
        sessions: const [
          SessionInput(name: 'A', startTime: '09:00', endTime: '09:30'),
          SessionInput(name: 'B', startTime: '09:30', endTime: '11:00'),
        ],
      );
      await pumpProgrammeField(tester, initialValue: seeded);
      expect(find.byType(CLDatePicker), findsNWidgets(2));

      final form = await pumpProgrammeField(
        tester,
        initialValue: seeded,
        enabled: false,
      );

      expect(find.byType(CLDatePicker), findsNothing);
      await tester.tap(find.byType(WeekdayChip).at(4), warnIfMissed: false);
      await tester.tap(find.text('Clear'), warnIfMissed: false);
      await tester.tap(find.text('1:30'), warnIfMissed: false);
      await tester.tap(find.byType(IconButton).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expectInputsDisabled(tester);
      expect(
        tester.widget<ShadTimePicker>(find.byType(ShadTimePicker)).enabled,
        isFalse,
      );
      expect(shownDurations(tester), ['0:30', '1:30']);
      expect(find.text('1 Sep 2030'), findsOneWidget);
      expect(programmeValue(form), seeded);
    });
  });
}
