import '../../models/one_off_schedule_data.dart';

/// Pure validators for `OneOffScheduleForm`.
class OneOffScheduleFormValidators {
  const OneOffScheduleFormValidators._();

  /// Shown when no venue is chosen.
  static const String venueRequiredMessage = 'Please select a venue';

  /// Shown when the new start is before the one the one-off has now — by
  /// [notEarlier], and by the host when the server refuses the move
  /// (`POSTPONE_ONLY`).
  static const String postponeOnlyMessage =
      'A one-off can only be moved to a later time, not an earlier one.';

  /// A venue must be chosen.
  static String? venue(int? value) =>
      value == null ? venueRequiredMessage : null;

  /// The local start [schedule] describes, or `null` while its date or
  /// start time is missing.
  static DateTime? startOf(OneOffScheduleData schedule) {
    final date = schedule.date;
    final time = schedule.startTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// `null` when [schedule] starts at or after [notBefore] (or either is
  /// unknown); else [postponeOnlyMessage].
  static String? notEarlier(OneOffScheduleData schedule, DateTime? notBefore) {
    final start = startOf(schedule);
    if (start == null || notBefore == null) return null;
    return start.isBefore(notBefore.toLocal()) ? postponeOnlyMessage : null;
  }
}
