/// Field-id constants for the `ShadForm` inside `OneOffScheduleForm`.
class OneOffScheduleFormFields {
  const OneOffScheduleFormFields._();

  /// The date, start time and duration, a `OneOffScheduleData`.
  static const String scheduleId = 'schedule';

  /// The chosen venue's id.
  static const String venueId = 'venue';

  /// The split into sessions, a `List<SessionInput>`.
  static const String sessionsId = 'sessions';
}
