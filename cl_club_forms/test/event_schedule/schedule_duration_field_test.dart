// The Duration of a schedule is picked, not typed (issue 65): hours and
// minutes in 15-minute steps, from 15 minutes to the cluster's longest. A
// length the picker does not offer, of an existing event, shows as it is
// and is kept until another is picked.
import 'package:cl_club_forms/src/models/camp_schedule_data.dart';
import 'package:cl_club_forms/src/models/one_off_schedule_data.dart';
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/one_off_schedule_fields.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/schedule_duration_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/form_harness.dart';
import '../support/programme_timetable_schedule_cluster.dart';
import '../support/programme_timetable_support.dart';

const _fieldId = 'schedule';
const int _eightHours = 8 * 60;

/// Mounts the field alone, showing [minutes], and returns what it reports.
Future<List<int>> _pumpField(
  WidgetTester tester, {
  required int minutes,
  int longestMinutes = _eightHours,
  bool enabled = true,
}) async {
  final reported = <int>[];
  await pumpForm(
    tester,
    ScheduleDurationField(
      minutes: minutes,
      longestMinutes: longestMinutes,
      enabled: enabled,
      onChanged: reported.add,
    ),
  );
  return reported;
}

Future<GlobalKey<ShadFormState>> _pumpCamp(
  WidgetTester tester,
  CampScheduleData initialValue,
) => pumpFieldInForm(
  tester,
  CampScheduleFormField(
    id: _fieldId,
    initialValue: initialValue,
    validator: CampScheduleFormField.aggregateValidator,
  ),
);

Future<GlobalKey<ShadFormState>> _pumpOneOff(
  WidgetTester tester,
  OneOffScheduleData initialValue,
) => pumpFieldInForm(
  tester,
  OneOffScheduleFormField(
    id: _fieldId,
    initialValue: initialValue,
    validator: OneOffScheduleFormField.aggregateValidator,
  ),
);

CampScheduleData _campValue(GlobalKey<ShadFormState> form) =>
    form.currentState!.value[_fieldId] as CampScheduleData;

OneOffScheduleData _oneOffValue(GlobalKey<ShadFormState> form) =>
    form.currentState!.value[_fieldId] as OneOffScheduleData;

CampScheduleData _camp({int durationMinutes = 120}) => CampScheduleData(
  startDate: DateTime(2030, 7),
  sessionStartTime: kSixAm,
  durationMinutes: durationMinutes,
);

OneOffScheduleData _oneOff({int durationMinutes = 120}) => OneOffScheduleData(
  date: DateTime(2030, 7),
  startTime: kSixAm,
  durationMinutes: durationMinutes,
);

/// No input of the Duration row takes typed text.
void _expectNothingToType() {
  expect(
    find.descendant(
      of: scheduleRow('Duration'),
      matching: find.byType(EditableText),
    ),
    findsNothing,
  );
}

void main() {
  group('Issue 65: ScheduleDurationField', () {
    testWidgets('Issue 65: it shows the length as hours and minutes and '
        'offers quarter hours up to the longest', (tester) async {
      await _pumpField(tester, minutes: 90);
      expect(shownDuration(tester), '1:30');

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 0), [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(offeredInColumn(tester, 1), [0, 15, 30, 45]);
    });

    testWidgets('Issue 65: under an hour the shortest offered is 15 '
        'minutes', (tester) async {
      await _pumpField(tester, minutes: 45);

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 1), [15, 30, 45]);
    });

    testWidgets('Issue 65: at the longest hour no minutes are offered '
        'beyond it', (tester) async {
      await _pumpField(tester, minutes: 240, longestMinutes: 240);

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 0), [0, 1, 2, 3, 4]);
      expect(offeredInColumn(tester, 1), [0]);
    });

    testWidgets('Issue 65: an hour and a minute picked are reported in '
        'minutes', (tester) async {
      final reported = await _pumpField(tester, minutes: 90);

      await pickDurationHour(tester, 3);
      expect(reported, [210]);

      await pickDurationMinute(tester, 45);
      expect(reported, [210, 105]);
    });

    testWidgets('Issue 65: zero hours on a whole hour gives the shortest', (
      tester,
    ) async {
      final reported = await _pumpField(tester, minutes: 120);

      await pickDurationHour(tester, 0);

      expect(reported, [15]);
    });

    testWidgets('Issue 65: an hour that would pass the longest gives the '
        'longest', (tester) async {
      final reported = await _pumpField(
        tester,
        minutes: 210,
        longestMinutes: 240,
      );

      await pickDurationHour(tester, 4);

      expect(reported, [240]);
    });

    testWidgets('Issue 65: a length longer than the longest shows as it is, '
        'and the hours reach it', (tester) async {
      await _pumpField(tester, minutes: 600);
      expect(shownDuration(tester), '10:00');

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 0).last, 10);
    });

    testWidgets('Issue 65: from a length longer than the longest, an hour '
        'above the longest gives the longest', (tester) async {
      final reported = await _pumpField(tester, minutes: 600);

      await pickDurationHour(tester, 9);

      expect(reported, [_eightHours]);
    });

    testWidgets('Issue 65: a length off the step shows as it is', (
      tester,
    ) async {
      await _pumpField(tester, minutes: 50);
      expect(shownDuration(tester), '0:50');

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 1), [15, 30, 45]);
    });

    testWidgets('Issue 65: from a length off the step, what is picked is '
        'on the step', (tester) async {
      final reported = await _pumpField(tester, minutes: 50);

      await pickDurationHour(tester, 1);
      expect(reported, [105]);

      await pickDurationMinute(tester, 30);
      expect(reported, [105, 30]);
    });

    testWidgets('Issue 65: a length under the shortest shows as it is', (
      tester,
    ) async {
      await _pumpField(tester, minutes: 10);

      expect(shownDuration(tester), '0:10');
    });

    testWidgets('Issue 65: picking the length shown reports nothing', (
      tester,
    ) async {
      final reported = await _pumpField(tester, minutes: 50);

      await pickDurationHour(tester, 0);

      expect(reported, isEmpty);
    });

    testWidgets('Issue 65: disabled, the picker does not open', (
      tester,
    ) async {
      await _pumpField(tester, minutes: 90, enabled: false);

      await tester.tap(durationPicker(), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(DurationPickerColumn), findsNothing);
    });
  });

  group('Issue 65: the Duration of a camp day', () {
    testWidgets('Issue 65: camp, Duration is a picker up to 8 hours and '
        'nothing is typed', (tester) async {
      await _pumpCamp(tester, _camp());
      _expectNothingToType();
      expect(shownDuration(tester), '2:00');

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 0).last, 8);
      expect(maxCampDurationMinutes, _eightHours);
    });

    testWidgets('Issue 65: camp, the length picked is the value', (
      tester,
    ) async {
      final form = await _pumpCamp(tester, _camp());

      await pickDuration(tester, 1, 30);

      expect(_campValue(form).durationMinutes, 90);
      expect(shownDuration(tester), '1:30');
      expect(form.currentState!.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 65: camp, a new duration resets the session split', (
      tester,
    ) async {
      final form = await _pumpCamp(
        tester,
        _camp().copyWith(sessions: kWarmUpAndDrills),
      );
      expect(shownDurations(tester), ['0:30', '1:30']);

      await pickDuration(tester, 3);

      expect(_campValue(form).durationMinutes, 180);
      expect(_campValue(form).sessions, isEmpty);
      expect(shownDurations(tester), ['3:00']);
    });

    testWidgets('Issue 65: camp, a day longer than 8 hours opens with its '
        'length and keeps it', (tester) async {
      final form = await _pumpCamp(tester, _camp(durationMinutes: 600));

      expect(shownDuration(tester), '10:00');
      expect(form.currentState!.saveAndValidate(), isTrue);
      expect(_campValue(form).durationMinutes, 600);
    });

    testWidgets('Issue 65: camp, a day off the step opens with its length '
        'and keeps it until another is picked', (tester) async {
      final form = await _pumpCamp(tester, _camp(durationMinutes: 100));

      expect(shownDuration(tester), '1:40');
      expect(form.currentState!.saveAndValidate(), isTrue);
      expect(_campValue(form).durationMinutes, 100);

      await pickDurationMinute(tester, 45);
      expect(_campValue(form).durationMinutes, 105);
    });
  });

  group('Issue 65: the Duration of a one-off', () {
    testWidgets('Issue 65: one-off, Duration is a picker up to 8 hours and '
        'nothing is typed', (tester) async {
      await _pumpOneOff(tester, _oneOff());
      _expectNothingToType();
      expect(shownDuration(tester), '2:00');

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 0).last, 8);
      expect(maxOneOffDurationMinutes, _eightHours);
    });

    testWidgets('Issue 65: one-off, the length picked is the value', (
      tester,
    ) async {
      final form = await _pumpOneOff(tester, _oneOff());

      await pickDuration(tester, 0, 45);

      expect(_oneOffValue(form).durationMinutes, 45);
      expect(shownDuration(tester), '0:45');
      expect(form.currentState!.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 65: one-off, a length longer than 8 hours or off '
        'the step opens as it is and is kept', (tester) async {
      for (final (minutes, shown) in [(600, '10:00'), (50, '0:50')]) {
        final form = await _pumpOneOff(
          tester,
          _oneOff(durationMinutes: minutes),
        );

        expect(shownDuration(tester), shown);
        expect(form.currentState!.saveAndValidate(), isTrue);
        expect(_oneOffValue(form).durationMinutes, minutes);
      }
    });
  });

  group('Issue 65: the Duration of a programme', () {
    testWidgets('Issue 65: programme, Duration is a picker up to 4 hours '
        'and nothing is typed', (tester) async {
      await pumpProgrammeField(tester, initialValue: validProgramme);
      _expectNothingToType();
      expect(shownDuration(tester), '2:00');

      await tapDurationPicker(tester);

      expect(offeredInColumn(tester, 0), [0, 1, 2, 3, 4]);
    });

    testWidgets('Issue 65: programme, the length picked is the value', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );

      await pickDuration(tester, 1, 15);

      expect(programmeValue(form).totalDurationMinutes, 75);
      expect(shownDuration(tester), '1:15');
      expect(await validateProgramme(tester, form), isTrue);
    });

    testWidgets('Issue 65: programme, four hours is the longest picked', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(totalDurationMinutes: 225),
      );

      await pickDurationHour(tester, 4);

      expect(programmeValue(form).totalDurationMinutes, 240);
      expect(await validateProgramme(tester, form), isTrue);
    });

    testWidgets('Issue 65: programme, a new duration resets the session '
        'split', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(
          sessions: const [
            SessionInput(name: 'A', startTime: '09:00', endTime: '09:30'),
            SessionInput(name: 'B', startTime: '09:30', endTime: '11:00'),
          ],
        ),
      );

      await pickDuration(tester, 1);

      expect(programmeValue(form).totalDurationMinutes, 60);
      expect(programmeValue(form).sessions, isEmpty);
      expect(shownDurations(tester), ['1:00']);
    });

    testWidgets('Issue 65: programme, a length off the step opens as it is '
        'and is kept', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(totalDurationMinutes: 50),
      );

      expect(shownDuration(tester), '0:50');
      expect(await validateProgramme(tester, form), isTrue);
      expect(programmeValue(form).totalDurationMinutes, 50);
    });

    testWidgets('Issue 65: programme, a length longer than 4 hours opens '
        'showing its real length', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(totalDurationMinutes: 300),
      );

      expect(shownDuration(tester), '5:00');
      expect(programmeValue(form).totalDurationMinutes, 300);

      await tapDurationPicker(tester);
      expect(offeredInColumn(tester, 0).last, 5);
    });

    testWidgets('Issue 65: programme, a length longer than 4 hours is '
        'refused with its message until a shorter one is picked', (
      tester,
    ) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme.copyWith(totalDurationMinutes: 300),
      );

      expect(await validateProgramme(tester, form), isFalse);
      expect(find.text('Programme session cannot exceed 4h'), findsOneWidget);

      await pickDuration(tester, 4);

      expect(await validateProgramme(tester, form), isTrue);
      expect(programmeValue(form).totalDurationMinutes, 240);
      expect(find.text('Programme session cannot exceed 4h'), findsNothing);
    });
  });
}
