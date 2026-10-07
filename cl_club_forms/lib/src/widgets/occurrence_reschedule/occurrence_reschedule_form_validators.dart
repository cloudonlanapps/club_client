/// Pure validators for `OccurrenceRescheduleForm`.
class OccurrenceRescheduleFormValidators {
  const OccurrenceRescheduleFormValidators._();

  /// Shown when no venue is chosen.
  static const String venueRequiredMessage = 'Venue is required';

  /// A venue must be chosen.
  static String? venue(int? value) =>
      value == null ? venueRequiredMessage : null;
}
