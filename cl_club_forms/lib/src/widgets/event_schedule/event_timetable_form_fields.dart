/// Field-id constants for the `ShadForm` inside `EventTimetableForm`.
class EventTimetableFormFields {
  const EventTimetableFormFields._();

  /// The schedule being corrected. In the form it is the picker's index
  /// into the offered schedules; in the values `validate()` returns it is
  /// that schedule's own id (`int?`).
  static const String scheduleId = 'schedule';

  /// The split into sessions, a `List<SessionInput>`.
  static const String sessionsId = 'sessions';
}
