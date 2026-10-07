/// Field-id constants for the `ShadForm` inside `OccurrenceRescheduleForm`.
///
/// `scheduleId` carries the form-local `OneOffScheduleData` (date / start
/// time / duration) produced by the reused `OneOffScheduleFormField`;
/// `venueId` carries the picked venue's id. A single camp day is,
/// schedule-wise, exactly a one-off session — date, start, duration — so the
/// form reuses that field rather than duplicating the date/time/duration trio.
class OccurrenceRescheduleFormFields {
  OccurrenceRescheduleFormFields._();

  static const String scheduleId = 'schedule';
  static const String venueId = 'venue';
}
