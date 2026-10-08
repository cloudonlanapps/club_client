// Issue 108: the rules the schedule clusters' inputs check are static
// methods of their validator classes, with the messages they always had.
import 'package:cl_club_forms/src/widgets/event_schedule/camp_schedule_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/one_off_schedule_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

const ShadTimeOfDay _nine = ShadTimeOfDay(hour: 9, minute: 0, second: 0);

void main() {
  group('Issue 108: CampScheduleFormValidators', () {
    test('Issue 108: the start date is required', () {
      expect(
        CampScheduleFormValidators.startDate(null),
        'Start date is required',
      );
      expect(CampScheduleFormValidators.startDate(DateTime(2026, 8, 3)), null);
    });

    test('Issue 108: Training Days is a whole number of at least one', () {
      expect(CampScheduleFormValidators.trainingDays(''), 'Required');
      for (final value in ['x', '0', '-2', '1.5']) {
        expect(
          CampScheduleFormValidators.trainingDays(value),
          'Enter a valid number',
          reason: value,
        );
      }
      expect(CampScheduleFormValidators.trainingDays('1'), null);
      expect(CampScheduleFormValidators.trainingDays('7'), null);
    });

    test('Issue 108: the start time is required', () {
      expect(
        CampScheduleFormValidators.startTime(null),
        'Start time is required',
      );
      expect(CampScheduleFormValidators.startTime(_nine), null);
    });
  });

  group('Issue 108: OneOffScheduleFormValidators', () {
    test('Issue 108: the date is required', () {
      expect(OneOffScheduleFormValidators.date(null), 'Date is required');
      expect(OneOffScheduleFormValidators.date(DateTime(2026, 8, 3)), null);
    });

    test('Issue 108: the start time is required', () {
      expect(
        OneOffScheduleFormValidators.startTime(null),
        'Start time is required',
      );
      expect(OneOffScheduleFormValidators.startTime(_nine), null);
    });
  });

  group('Issue 108: ProgrammeScheduleFormValidators', () {
    test('Issue 108: at least one day is picked', () {
      expect(
        ProgrammeScheduleFormValidators.weekdays(null),
        'Pick at least one day',
      );
      expect(
        ProgrammeScheduleFormValidators.weekdays(const {}),
        'Pick at least one day',
      );
      expect(
        ProgrammeScheduleFormValidators.weekdays({DateTime.monday}),
        null,
      );
    });

    test('Issue 108: the start date is required', () {
      expect(
        ProgrammeScheduleFormValidators.startDate(null),
        'Start date is required',
      );
      expect(
        ProgrammeScheduleFormValidators.startDate(DateTime(2026, 8, 3)),
        null,
      );
    });

    test('Issue 108: the start time is required', () {
      expect(
        ProgrammeScheduleFormValidators.startTime(null),
        'Start time is required',
      );
      expect(ProgrammeScheduleFormValidators.startTime(_nine), null);
    });
  });
}
