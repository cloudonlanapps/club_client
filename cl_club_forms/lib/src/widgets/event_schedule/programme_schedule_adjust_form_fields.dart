/// Field-id constants for the `ShadForm` inside
/// `ProgrammeScheduleAdjustForm`.
class ProgrammeScheduleAdjustFormFields {
  const ProgrammeScheduleAdjustFormFields._();

  /// The session the new schedule starts from, its start as a `DateTime`.
  static const String fromId = 'from';

  /// The weekdays, start time, duration and sessions, a
  /// `ProgrammeScheduleData`.
  static const String scheduleId = 'schedule';

  /// The chosen venue's id.
  static const String venueId = 'venue';
}
