import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CampScheduleFormFields,
        EventCancellationFormFields,
        EventCreateFormFields,
        EventFormFields,
        EventTimetableFormFields,
        OccurrenceRescheduleFormFields,
        OneOffScheduleFormFields,
        ProgrammeEndDateFormFields,
        ProgrammeScheduleAdjustFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ageSchemaFieldIds, schemaFieldErrors;

/// The server's names for the fields of an event and of a session, as a
/// schema rejection gives them (club_client#114), and for each event form
/// the field that holds each.
///
/// A form's map names only what that form sends. A date, a time and a rule
/// are one schedule field in a form, so the server's start, end and rule
/// all show on it.
abstract final class EventSchemaFields {
  /// The title.
  static const String title = 'title';

  /// The visibility.
  static const String visibility = 'visibility';

  /// The venue.
  static const String venueId = 'venueId';

  /// The start of the first session.
  static const String startTimeUtc = 'startTimeUtc';

  /// The end of the first session.
  static const String endTimeUtc = 'endTimeUtc';

  /// The recurrence rule.
  static const String rrule = 'rrule';

  /// The timetable of a day.
  static const String sessions = 'sessions';

  /// The schedule a timetable correction is for.
  static const String scheduleId = 'scheduleId';

  /// The gender criterion.
  static const String gender = 'gender';

  /// The organizer.
  static const String organizerName = 'organizerName';

  /// The coaches.
  static const String coachNames = 'coachNames';

  /// The session a split or a camp's cancellation takes effect from.
  static const String effectiveDateTimeUtc = 'effectiveDateTimeUtc';

  /// The session a programme ends before.
  static const String cutoffTimeUtc = 'cutoffTimeUtc';

  /// The reason of a cancellation or an end date.
  static const String reason = 'reason';

  /// The new start of a rescheduled session.
  static const String newStartTimeUtc = 'newStartTimeUtc';

  /// The new duration of a rescheduled session.
  static const String newDurationMinutes = 'newDurationMinutes';

  /// The new venue of a rescheduled session.
  static const String newVenueId = 'newVenueId';

  /// The create form.
  static const Map<String, String> create = {
    title: EventCreateFormFields.titleId,
    visibility: EventCreateFormFields.visibilityId,
    venueId: EventCreateFormFields.venueId,
    startTimeUtc: EventCreateFormFields.scheduleId,
    endTimeUtc: EventCreateFormFields.scheduleId,
    rrule: EventCreateFormFields.scheduleId,
    sessions: EventCreateFormFields.scheduleId,
  };

  /// The eligibility editor.
  static const Map<String, String> eligibility = {
    gender: EventFormFields.genderId,
    ...ageSchemaFieldIds,
  };

  /// The organizer and coaches editor.
  static const Map<String, String> staff = {
    organizerName: EventFormFields.organizerNameId,
    coachNames: EventFormFields.coachNamesId,
    effectiveDateTimeUtc: EventFormFields.effectiveFromId,
  };

  /// The timetable editor.
  static const Map<String, String> timetable = {
    sessions: EventTimetableFormFields.sessionsId,
    scheduleId: EventTimetableFormFields.scheduleId,
  };

  /// A camp's schedule editor.
  static const Map<String, String> campSchedule = {
    startTimeUtc: CampScheduleFormFields.scheduleId,
    endTimeUtc: CampScheduleFormFields.scheduleId,
    rrule: CampScheduleFormFields.scheduleId,
    sessions: CampScheduleFormFields.scheduleId,
  };

  /// A one-off's schedule editor.
  static const Map<String, String> oneOffSchedule = {
    startTimeUtc: OneOffScheduleFormFields.scheduleId,
    endTimeUtc: OneOffScheduleFormFields.scheduleId,
    venueId: OneOffScheduleFormFields.venueId,
    sessions: OneOffScheduleFormFields.sessionsId,
  };

  /// A programme's Adjust Schedule form.
  static const Map<String, String> programmeAdjust = {
    effectiveDateTimeUtc: ProgrammeScheduleAdjustFormFields.fromId,
    startTimeUtc: ProgrammeScheduleAdjustFormFields.scheduleId,
    endTimeUtc: ProgrammeScheduleAdjustFormFields.scheduleId,
    rrule: ProgrammeScheduleAdjustFormFields.scheduleId,
    sessions: ProgrammeScheduleAdjustFormFields.scheduleId,
    venueId: ProgrammeScheduleAdjustFormFields.venueId,
  };

  /// A programme's end date form.
  static const Map<String, String> programmeEndDate = {
    cutoffTimeUtc: ProgrammeEndDateFormFields.lastDayId,
    reason: ProgrammeEndDateFormFields.reasonId,
  };

  /// The cancellation form of a camp or a one-off.
  static const Map<String, String> cancellation = {
    effectiveDateTimeUtc: EventCancellationFormFields.fromSessionId,
    reason: EventCancellationFormFields.reasonId,
  };

  /// A session's reschedule form.
  static const Map<String, String> occurrenceReschedule = {
    newStartTimeUtc: OccurrenceRescheduleFormFields.scheduleId,
    newDurationMinutes: OccurrenceRescheduleFormFields.scheduleId,
    newVenueId: OccurrenceRescheduleFormFields.venueId,
  };

  /// What the rename dialog shows on the name for a rename that failed with
  /// [error]: the server's reason when its schema rejects the title, else
  /// [fallback].
  static String renameRefusal(Object error, {required String fallback}) =>
      schemaFieldErrors(error, const {title: title})[title] ?? fallback;
}
