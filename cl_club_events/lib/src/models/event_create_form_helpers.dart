import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CampScheduleData,
        EventCreateForm,
        EventCreateFormFields,
        EventFormType,
        EventFormVisibility,
        OneOffScheduleData,
        ProgrammeScheduleData,
        SessionInput,
        SessionSplitField;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';

import '../utils/camp_rrule_validator.dart';
import '../utils/programme_schedule_sessions.dart';

/// SDK ↔ `EventCreateForm` adapter (the form's single boundary).
///
/// Form → SDK is [EventCreateFormSubmit.create]; SDK → form initial values is
/// [buildEventCreateFormInitialValues] (create-only, so it just returns the
/// form's seeded defaults for [type]).

/// Initial flat form values for creating an event of [type].
Map<String, dynamic> buildEventCreateFormInitialValues(EventFormType type) =>
    EventCreateForm.defaultValues(type);

/// Assembled schedule fields ready for the SDK create call.
typedef _AssembledSchedule = ({
  DateTime startTimeUtc,
  DateTime endTimeUtc,
  String? rrule,
  List<EventSession>? sessions,
});

/// Translates the flat form values into the minimal `createEvent` call.
class EventCreateFormSubmit {
  EventCreateFormSubmit._();

  static final RruleUtil _rruleUtil = RruleUtil();

  /// Create an event from the form's flat [values]. Only the minimal fields
  /// flow through here — title, visibility, venue and the schedule; the rest
  /// (eligibility, organizer/coaches, gallery, …) are edited after creation.
  static Future<Event> create({
    required EventFormType type,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    final title = (values[EventCreateFormFields.titleId] as String).trim();
    final visibility = _toVisibility(
      values[EventCreateFormFields.visibilityId] as EventFormVisibility,
    );
    final venueId = values[EventCreateFormFields.venueId] as int;
    final schedule = values[EventCreateFormFields.scheduleId] as Object;

    final assembled = _assemble(type, schedule);
    return notifier.createEvent(
      title: title,
      description: '',
      type: _toEventType(type),
      visibility: visibility,
      venueId: venueId,
      startTimeUtc: assembled.startTimeUtc,
      endTimeUtc: assembled.endTimeUtc,
      rrule: assembled.rrule,
      sessions: assembled.sessions,
    );
  }

  static _AssembledSchedule _assemble(EventFormType type, Object schedule) {
    switch (type) {
      case EventFormType.oneOff:
        final data = schedule as OneOffScheduleData;
        final start = DateTime(
          data.date!.year,
          data.date!.month,
          data.date!.day,
          data.startTime!.hour,
          data.startTime!.minute,
        );
        final end = start.add(Duration(minutes: data.durationMinutes));
        return (
          startTimeUtc: start.toUtc(),
          endTimeUtc: end.toUtc(),
          rrule: null,
          sessions: null,
        );
      case EventFormType.camp:
        final data = schedule as CampScheduleData;
        final start = DateTime(
          data.startDate!.year,
          data.startDate!.month,
          data.startDate!.day,
          data.sessionStartTime!.hour,
          data.sessionStartTime!.minute,
        );
        final end = start.add(Duration(minutes: data.durationMinutes));
        final totalDays = data.trainingDays + data.excludedDates.length;
        final combinedRrule = _rruleUtil.buildRruleWithExdates(
          'FREQ=DAILY;COUNT=$totalDays',
          data.excludedDates.toList()..sort(),
        );
        final rruleError = CampRruleValidator.validate(combinedRrule);
        if (rruleError != null) {
          throw ArgumentError(rruleError);
        }
        return (
          startTimeUtc: start.toUtc(),
          endTimeUtc: end.toUtc(),
          rrule: combinedRrule,
          sessions: data.sessions.isNotEmpty
              ? _toSessions(data.sessions)
              : null,
        );
      case EventFormType.programme:
        final data = schedule as ProgrammeScheduleData;
        final start = DateTime(
          data.startDate!.year,
          data.startDate!.month,
          data.startDate!.day,
          data.sessionStartTime!.hour,
          data.sessionStartTime!.minute,
        );
        final end = start.add(Duration(minutes: data.totalDurationMinutes));
        return (
          startTimeUtc: start.toUtc(),
          endTimeUtc: end.toUtc(),
          rrule: _programmeRrule(data, start),
          sessions: data.sessions.isNotEmpty
              ? _toSessions(data.sessions)
              : null,
        );
    }
  }

  static List<EventSession> _toSessions(List<SessionInput> inputs) => [
    for (final s in inputs)
      EventSession(
        name: s.name,
        periodMinutes: SessionSplitField.sessionMinutes(s),
      ),
  ];

  /// The weekly rule of a programme whose first session starts at the local
  /// [start]. The form speaks local weekdays; the rule names its days in
  /// UTC, as the server expands it from the UTC start (club_client#119).
  static String? _programmeRrule(ProgrammeScheduleData data, DateTime start) {
    if (data.weekdays.isEmpty) return null;
    final weekly = programmeRruleFor(
      shiftWeekdays(data.weekdays, -localDayShiftOf(start)),
    );
    if (data.hasNoEndDate || data.endDate == null) return weekly;
    return '$weekly;UNTIL=${_formatUntil(data.endDate!)}';
  }

  static String _formatUntil(DateTime date) {
    final utc = date.toUtc();
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '${utc.year}$m${d}T235959Z';
  }

  static EventType _toEventType(EventFormType type) => switch (type) {
    EventFormType.programme => EventType.programme,
    EventFormType.camp => EventType.camp,
    EventFormType.oneOff => EventType.oneOff,
  };

  static Visibility _toVisibility(EventFormVisibility visibility) =>
      visibility == EventFormVisibility.public
      ? Visibility.public
      : Visibility.private;
}
