import 'package:cl_club_events/src/models/camp_event_form_helpers.dart';
import 'package:cl_club_events/src/models/event_cancellation_messages.dart';
import 'package:cl_club_events/src/models/event_schema_fields.dart';
import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart';
import 'package:cl_club_events/src/utils/event_cancellation_error.dart';
import 'package:cl_club_events/src/utils/event_create_error.dart';
import 'package:cl_club_events/src/utils/programme_end_date_messages.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        AgeEligibilityFormFields,
        CampScheduleFormFields,
        EventCancellationFormFields,
        EventCreateFormFields,
        EventFormFields,
        EventTimetableFormFields,
        OccurrenceRescheduleFormFields,
        OneOffScheduleFormFields,
        ProgrammeEndDateFormFields,
        ProgrammeScheduleAdjustFormFields;
import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

const _fallback = 'Could not save.';

/// A schema rejection (422) naming [fields], each with the reason "refused".
ServerException _rejection(List<List<Object>> fields) => ServerException(
  statusCode: 422,
  code: SdkErrorCode.validationError,
  message: 'refused',
  details: {
    ServerException.refusedFieldsKey: [
      for (final loc in fields) {'loc': loc, 'msg': 'refused'},
    ],
  },
);

/// A rejection that names nothing an event form holds.
final ServerException _aboutNothing = _rejection([
  ['body'],
  ['body', 'version'],
]);

ServerException _refused(String code) =>
    ServerException(statusCode: 422, code: code, message: 'raw');

void main() {
  group('Issue 114: a schema rejection shows on the event field it names', () {
    test('Issue 114: event create puts the title, the visibility and the '
        'venue on their fields, and the times, the rule and the timetable '
        'on the schedule', () {
      final refusal = eventCreateRefusal(
        _rejection([
          ['body', 'title'],
          ['body', 'visibility'],
          ['body', 'venueId'],
          ['body', 'startTimeUtc'],
          ['body', 'rrule'],
          ['body', 'sessions', 0, 'startMinute'],
        ]),
        fallback: _fallback,
      );

      expect(refusal?.fieldErrors, {
        EventCreateFormFields.titleId: 'Refused',
        EventCreateFormFields.visibilityId: 'Refused',
        EventCreateFormFields.venueId: 'Refused',
        EventCreateFormFields.scheduleId: 'Refused',
      });
      expect(refusal?.formError, isNull);
      expect(eventCreateRefusal(_aboutNothing, fallback: _fallback), isNull);
    });

    test('Issue 114: eligibility puts it on the gender and the ages', () {
      final refusal = EventFormSubmit.eligibilityRefusal(
        _rejection([
          ['body', 'gender'],
          ['body', 'minAge', 'years'],
          ['body', 'maxAge', 'days'],
          ['body', 'strictAge'],
        ]),
      );

      expect(refusal?.fieldErrors.keys, {
        EventFormFields.genderId,
        AgeEligibilityFormFields.minAgeYearsId,
        AgeEligibilityFormFields.maxAgeDaysId,
        AgeEligibilityFormFields.strictAgeId,
      });
      expect(EventFormSubmit.eligibilityRefusal(_aboutNothing), isNull);
    });

    test('Issue 114: organizer and coaches puts it on the organizer, the '
        'coaches and the From session', () {
      final refusal = EventFormSubmit.staffRefusal(
        _rejection([
          ['body', 'organizerName'],
          ['body', 'coachNames', 1],
          ['body', 'effectiveDateTimeUtc'],
        ]),
      );

      expect(refusal?.fieldErrors.keys, {
        EventFormFields.organizerNameId,
        EventFormFields.coachNamesId,
        EventFormFields.effectiveFromId,
      });
      expect(EventFormSubmit.staffRefusal(_aboutNothing), isNull);
    });

    test('Issue 114: Adjust Schedule puts it on the From session, the '
        'schedule and the venue, and keeps its own refusals', () {
      final refusal = ProgrammeScheduleFormSubmit.adjustRefusal(
        _rejection([
          ['body', 'effectiveDateTimeUtc'],
          ['body', 'rrule'],
          ['body', 'venueId'],
        ]),
        message: _fallback,
        fallback: _fallback,
      );

      expect(refusal?.fieldErrors.keys, {
        ProgrammeScheduleAdjustFormFields.fromId,
        ProgrammeScheduleAdjustFormFields.scheduleId,
        ProgrammeScheduleAdjustFormFields.venueId,
      });
      expect(
        ProgrammeScheduleFormSubmit.adjustRefusal(
          _refused(SdkErrorCode.cutoffTooSoon),
          message: 'Pick a later one.',
          fallback: _fallback,
        )?.fieldErrors,
        {ProgrammeScheduleAdjustFormFields.fromId: 'Pick a later one.'},
      );
      expect(
        ProgrammeScheduleFormSubmit.adjustRefusal(
          _aboutNothing,
          message: _fallback,
          fallback: _fallback,
        ),
        isNull,
        reason: 'it is a toast',
      );
    });

    test('Issue 114: the end date form puts it on the last day and the '
        'reason, and keeps its own refusals', () {
      expect(
        programmeEndDateRefusal(
          _rejection([
            ['body', 'cutoffTimeUtc'],
            ['body', 'reason'],
          ]),
          dayChosen: true,
        )?.fieldErrors,
        {
          ProgrammeEndDateFormFields.lastDayId: 'Refused',
          ProgrammeEndDateFormFields.reasonId: 'Refused',
        },
      );
      expect(
        programmeEndDateRefusal(
          _refused(SdkErrorCode.cutoffTooSoon),
          dayChosen: true,
        )?.fieldErrors.keys,
        {ProgrammeEndDateFormFields.lastDayId},
      );
      expect(
        programmeEndDateRefusal(
          _refused(SdkErrorCode.invalidState),
          dayChosen: true,
        )?.formError,
        programmeEndDateOutdatedMessage,
      );
      expect(programmeEndDateRefusal(_aboutNothing, dayChosen: true), isNull);
    });

    test('Issue 114: the cancellation form puts it on the session and the '
        'reason, and keeps its own refusals', () {
      expect(
        eventCancellationRefusal(
          _rejection([
            ['body', 'effectiveDateTimeUtc'],
            ['body', 'reason'],
          ]),
          isCamp: true,
          message: _fallback,
          fallback: _fallback,
        )?.fieldErrors,
        {
          EventCancellationFormFields.fromSessionId: 'Refused',
          EventCancellationFormFields.reasonId: 'Refused',
        },
      );
      expect(
        eventCancellationRefusal(
          _refused(SdkErrorCode.cancellationLeadTimeViolated),
          isCamp: true,
          message: EventCancellationMessages.tooClose,
          fallback: _fallback,
        )?.fieldErrors,
        {
          EventCancellationFormFields.fromSessionId:
              EventCancellationMessages.tooClose,
        },
      );
      expect(
        eventCancellationRefusal(
          _refused(SdkErrorCode.cancellationLeadTimeViolated),
          isCamp: false,
          message: EventCancellationMessages.tooClose,
          fallback: _fallback,
        )?.formError,
        EventCancellationMessages.tooClose,
        reason: 'a one-off has no session to pick',
      );
    });

    test('Issue 114: the timetable, the camp schedule, the one-off schedule '
        'and the session reschedule each name their own fields', () {
      final rejection = _rejection([
        ['body', 'sessions', 2, 'durationMinutes'],
        ['body', 'startTimeUtc'],
        ['body', 'venueId'],
        ['body', 'newStartTimeUtc'],
        ['body', 'newVenueId'],
      ]);

      expect(schemaFieldErrors(rejection, EventSchemaFields.timetable).keys, {
        EventTimetableFormFields.sessionsId,
      });
      expect(
        schemaFieldErrors(rejection, EventSchemaFields.campSchedule).keys,
        {CampScheduleFormFields.scheduleId},
      );
      expect(
        schemaFieldErrors(rejection, EventSchemaFields.oneOffSchedule).keys,
        {
          OneOffScheduleFormFields.sessionsId,
          OneOffScheduleFormFields.scheduleId,
          OneOffScheduleFormFields.venueId,
        },
      );
      expect(
        schemaFieldErrors(
          rejection,
          EventSchemaFields.occurrenceReschedule,
        ).keys,
        {
          OccurrenceRescheduleFormFields.scheduleId,
          OccurrenceRescheduleFormFields.venueId,
        },
      );
    });

    test('Issue 114: event rename shows the reason on the name', () {
      expect(
        EventSchemaFields.renameRefusal(
          _rejection([
            ['body', 'title'],
          ]),
          fallback: _fallback,
        ),
        'Refused',
      );
      expect(
        EventSchemaFields.renameRefusal(_aboutNothing, fallback: _fallback),
        _fallback,
      );
    });
  });
}
