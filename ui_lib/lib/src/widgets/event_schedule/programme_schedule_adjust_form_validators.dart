/// Pure validators for `ProgrammeScheduleAdjustForm`.
class ProgrammeScheduleAdjustFormValidators {
  const ProgrammeScheduleAdjustFormValidators._();

  /// Shown when no From session is chosen.
  static const String fromRequiredMessage =
      'Pick the session the new schedule starts from';

  /// Shown when the chosen From is not one of the offered session starts.
  static const String fromNotASessionMessage =
      'The new schedule can only start from an upcoming session';

  /// Shown when no venue is chosen.
  static const String venueRequiredMessage = 'Please select a venue';

  /// The From session must be one of [options]: the upcoming session starts
  /// of the present schedule.
  static String? from(DateTime? value, List<DateTime> options) {
    if (value == null) return fromRequiredMessage;
    final offered = options.any((o) => o.isAtSameMomentAs(value));
    return offered ? null : fromNotASessionMessage;
  }

  /// A venue must be chosen.
  static String? venue(int? value) =>
      value == null ? venueRequiredMessage : null;
}
