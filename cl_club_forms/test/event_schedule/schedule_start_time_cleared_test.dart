// A start time with an empty part is not a time (issue 66): in every form
// that has a Start Time, clearing its hour or its minute empties the field,
// and a required start time is refused with its message.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/event_create_form_support.dart';
import '../support/form_harness.dart';
import '../support/programme_timetable_adjust_fixtures.dart';
import '../support/programme_timetable_schedule_cluster.dart';
import '../support/programme_timetable_support.dart'
    hide pickOption, pumpFieldInForm;

const String _required = 'Start time is required';

/// Empties the hour (part 0) or the minute (part 1) of the start time, as
/// deleting its digits does.
Future<void> _clearPart(WidgetTester tester, int part) async {
  await tester.enterText(timePickerInputs().at(part), '');
  await tester.pumpAndSettle();
}

/// The message under the Start Time row.
Finder _refusedOnStartTime() => textInRow('Start Time', _required);

final CampScheduleData _camp = CampScheduleData(
  startDate: DateTime(2030, 7),
  sessionStartTime: kSixAm,
  sessions: kWarmUpAndDrills,
);

final OneOffScheduleData _oneOff = OneOffScheduleData(
  date: DateTime(2030, 7),
  startTime: kSixAm,
);

void main() {
  group('Issue 66: a start time with an empty part, camp', () {
    testWidgets('Issue 66: CampScheduleForm, the hour cleared empties the '
        'start time and is refused', (tester) async {
      final key = GlobalKey<CampScheduleFormState>();
      await pumpForm(tester, CampScheduleForm(key: key, initialValue: _camp));
      expect(key.currentState!.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });

    testWidgets('Issue 66: CampScheduleForm, the hour typed again brings '
        'the start time and the split back', (tester) async {
      final key = GlobalKey<CampScheduleFormState>();
      await pumpForm(tester, CampScheduleForm(key: key, initialValue: _camp));

      await _clearPart(tester, 0);
      await tester.enterText(timePickerInputs().at(0), '6');
      await tester.pumpAndSettle();

      final values = key.currentState!.validate();
      expect(values, isNotNull);
      expect(values![CampScheduleFormFields.scheduleId], _camp);
    });

    testWidgets('Issue 66: CampScheduleForm, the minute cleared empties the '
        'start time and is refused', (tester) async {
      final key = GlobalKey<CampScheduleFormState>();
      await pumpForm(tester, CampScheduleForm(key: key, initialValue: _camp));

      await _clearPart(tester, 1);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });

    testWidgets('Issue 66: EventCreateForm of a camp, the hour cleared is '
        'refused', (tester) async {
      final state = await pumpCreateForm(
        tester,
        EventFormType.camp,
        initial: completeCreateValues(EventFormType.camp),
      );
      expect(state.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });
  });

  group('Issue 66: a start time with an empty part, programme', () {
    testWidgets('Issue 66: the programme cluster, the hour cleared empties '
        'the start time and is refused', (tester) async {
      final form = await pumpProgrammeField(
        tester,
        initialValue: validProgramme,
      );
      expect(await validateProgramme(tester, form), isTrue);

      await _clearPart(tester, 0);

      expect(programmeValue(form).sessionStartTime, isNull);
      expect(await validateProgramme(tester, form), isFalse);
      expect(_refusedOnStartTime(), findsOneWidget);
    });

    testWidgets('Issue 66: ProgrammeScheduleAdjustForm, the hour cleared is '
        'refused', (tester) async {
      final state = await mountAdjustForm(tester);
      expect(state.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });

    testWidgets('Issue 66: EventCreateForm of a programme, the hour cleared '
        'is refused', (tester) async {
      final state = await pumpCreateForm(
        tester,
        EventFormType.programme,
        initial: completeCreateValues(EventFormType.programme),
      );
      expect(state.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });
  });

  group('Issue 66: a start time with an empty part, one-off', () {
    testWidgets('Issue 66: OneOffScheduleForm, the hour cleared empties the '
        'start time and is refused', (tester) async {
      final key = GlobalKey<OneOffScheduleFormState>();
      await pumpForm(
        tester,
        OneOffScheduleForm(
          key: key,
          initialValue: OneOffScheduleValue(schedule: _oneOff, venueId: 7),
          venues: adjustVenues,
        ),
      );
      expect(key.currentState!.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(key.currentState!.currentValue.schedule.startTime, isNull);
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });

    testWidgets('Issue 66: OccurrenceRescheduleForm, the hour cleared is '
        'refused', (tester) async {
      final key = GlobalKey<OccurrenceRescheduleFormState>();
      await pumpForm(
        tester,
        OccurrenceRescheduleForm(
          key: key,
          initialValues: {
            OccurrenceRescheduleFormFields.scheduleId: _oneOff,
            OccurrenceRescheduleFormFields.venueId: 7,
          },
          venues: adjustVenues,
        ),
      );
      expect(key.currentState!.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });

    testWidgets('Issue 66: EventCreateForm of a one-off, the hour cleared '
        'is refused', (tester) async {
      final state = await pumpCreateForm(
        tester,
        EventFormType.oneOff,
        initial: completeCreateValues(EventFormType.oneOff),
      );
      expect(state.validate(), isNotNull);

      await _clearPart(tester, 0);

      expect(state.validate(), isNull);
      await tester.pumpAndSettle();
      expect(_refusedOnStartTime(), findsOneWidget);
    });
  });
}
