import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_create/event_create_form_defaults.dart'
    show EventCreateFormDefaults;
import 'package:cl_club_forms/src/widgets/event_create/event_create_form_validators.dart'
    show EventCreateFormValidators;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

final _now = DateTime(2030, 6, 10, 10, 30, 45);

void main() {
  group('Issue 61: EventCreateFormValidators', () {
    test('Issue 61: a title that is empty or blank is refused by name', () {
      expect(EventCreateFormValidators.title(''), 'Title is required');
      expect(EventCreateFormValidators.title(' \n\t '), 'Title is required');
    });

    test('Issue 61: a title of one character is accepted, blanks around it '
        'ignored', () {
      expect(EventCreateFormValidators.title('A'), isNull);
      expect(EventCreateFormValidators.title('  A  '), isNull);
    });

    test('Issue 61: no venue is refused by name', () {
      expect(EventCreateFormValidators.venue(null), 'Please select a venue');
    });

    test('Issue 61: any venue id is accepted, zero included', () {
      expect(EventCreateFormValidators.venue(0), isNull);
      expect(EventCreateFormValidators.venue(42), isNull);
    });
  });

  group('Issue 61: EventCreateForm default values', () {
    for (final type in EventFormType.values) {
      test('Issue 61: a fresh ${type.name} has an empty title, is public '
          'and has no venue', () {
        final values = EventCreateForm.defaultValues(type, now: _now);

        expect(values.keys, [
          EventCreateFormFields.titleId,
          EventCreateFormFields.visibilityId,
          EventCreateFormFields.venueId,
          EventCreateFormFields.scheduleId,
        ]);
        expect(values[EventCreateFormFields.titleId], '');
        expect(
          values[EventCreateFormFields.visibilityId],
          EventFormVisibility.public,
        );
        expect(values[EventCreateFormFields.venueId], isNull);
      });
    }

    test('Issue 61: a camp starts a day ahead: five training days of 90 '
        'minutes from 06:00, no rest day, one session', () {
      final schedule =
          EventCreateForm.defaultValues(
                EventFormType.camp,
                now: _now,
              )[EventCreateFormFields.scheduleId]
              as CampScheduleData;

      expect(schedule.startDate, _now.add(const Duration(days: 1)));
      expect(schedule.trainingDays, 5);
      expect(
        schedule.sessionStartTime,
        const ShadTimeOfDay(hour: 6, minute: 0, second: 0),
      );
      expect(schedule.durationMinutes, 90);
      expect(schedule.excludedDates, isEmpty);
      expect(schedule.sessions, isEmpty);
    });

    test('Issue 61: a one-off starts an hour ahead, to the minute, for two '
        'hours', () {
      final schedule =
          EventCreateForm.defaultValues(
                EventFormType.oneOff,
                now: _now,
              )[EventCreateFormFields.scheduleId]
              as OneOffScheduleData;

      expect(schedule.date, DateTime(2030, 6, 10));
      expect(
        schedule.startTime,
        const ShadTimeOfDay(hour: 11, minute: 30, second: 0),
      );
      expect(schedule.durationMinutes, 120);
    });

    test('Issue 61: a one-off opened in the last hour of the day is dated '
        'tomorrow', () {
      final schedule =
          EventCreateForm.defaultValues(
                EventFormType.oneOff,
                now: DateTime(2030, 6, 10, 23, 15),
              )[EventCreateFormFields.scheduleId]
              as OneOffScheduleData;

      expect(schedule.date, DateTime(2030, 6, 11));
      expect(
        schedule.startTime,
        const ShadTimeOfDay(hour: 0, minute: 15, second: 0),
      );
    });

    test('Issue 61: a programme is ongoing, an hour long, on no weekday '
        'yet', () {
      final schedule =
          EventCreateForm.defaultValues(
                EventFormType.programme,
                now: _now,
              )[EventCreateFormFields.scheduleId]
              as ProgrammeScheduleData;

      expect(schedule.weekdays, isEmpty);
      expect(schedule.startDate, DateTime(2030, 6, 10));
      expect(
        schedule.sessionStartTime,
        const ShadTimeOfDay(hour: 11, minute: 0, second: 0),
      );
      expect(schedule.endDate, isNull);
      expect(schedule.hasNoEndDate, isTrue);
      expect(schedule.totalDurationMinutes, 60);
      expect(schedule.sessions, isEmpty);
    });

    test('Issue 61: the lead times and the camp defaults are the named '
        'constants', () {
      expect(EventCreateFormDefaults.leadTime, const Duration(hours: 1));
      expect(EventCreateFormDefaults.campLeadTime, const Duration(days: 1));
      expect(EventCreateFormDefaults.campTrainingDays, 5);
      expect(EventCreateFormDefaults.campDurationMinutes, 90);
    });

    test('Issue 61: without a now it seeds from the clock', () {
      final before = DateTime.now();
      final schedule =
          EventCreateForm.defaultValues(
                EventFormType.camp,
              )[EventCreateFormFields.scheduleId]
              as CampScheduleData;
      final after = DateTime.now();

      final start = schedule.startDate!.subtract(const Duration(days: 1));
      expect(start.isBefore(before), isFalse);
      expect(start.isAfter(after), isFalse);
    });
  });

  group("Issue 61: the create form's local types", () {
    test('Issue 61: each event type has the label the title hint uses', () {
      expect(
        {for (final type in EventFormType.values) type: type.label},
        {
          EventFormType.programme: 'Program',
          EventFormType.camp: 'Camp',
          EventFormType.oneOff: 'Event',
        },
      );
    });

    test('Issue 61: each visibility has its label', () {
      expect(EventFormVisibility.public.label, 'Public');
      expect(EventFormVisibility.private.label, 'Private');
    });

    test('Issue 61: venue options are equal by id and name', () {
      final a = EventVenueOption(id: int.parse('1'), name: 'Main Rink');
      const b = EventVenueOption(id: 1, name: 'Main Rink');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const EventVenueOption(id: 2, name: 'Main Rink')));
      expect(a, isNot(const EventVenueOption(id: 1, name: 'Other')));
    });

    test('Issue 61: the field ids are title, visibility, venue and '
        'schedule', () {
      expect(EventCreateFormFields.titleId, 'title');
      expect(EventCreateFormFields.visibilityId, 'visibility');
      expect(EventCreateFormFields.venueId, 'venue');
      expect(EventCreateFormFields.scheduleId, 'schedule');
      expect(EventCreateFormState.trackedIds, [
        'title',
        'visibility',
        'venue',
        'schedule',
      ]);
    });
  });
}
