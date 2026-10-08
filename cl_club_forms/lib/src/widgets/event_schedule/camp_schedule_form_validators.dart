import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

/// Pure validators for the inputs of a camp's schedule
/// (`CampScheduleFormField`, shown by `CampScheduleForm` and by
/// `EventCreateForm`).
class CampScheduleFormValidators {
  const CampScheduleFormValidators._();

  /// Shown when no start date is chosen.
  static const String startDateRequiredMessage = 'Start date is required';

  /// Shown when Training Days is left blank.
  static const String trainingDaysRequiredMessage = 'Required';

  /// Shown when Training Days is not a whole number of at least
  /// [minTrainingDays].
  static const String trainingDaysInvalidMessage = 'Enter a valid number';

  /// Shown when no start time is chosen.
  static const String startTimeRequiredMessage = 'Start time is required';

  /// The fewest training days a camp has.
  static const int minTrainingDays = 1;

  /// A start date must be chosen.
  static String? startDate(DateTime? date) =>
      date == null ? startDateRequiredMessage : null;

  /// Training Days is a whole number of at least [minTrainingDays].
  static String? trainingDays(String value) {
    if (value.isEmpty) return trainingDaysRequiredMessage;
    final days = int.tryParse(value);
    if (days == null || days < minTrainingDays) {
      return trainingDaysInvalidMessage;
    }
    return null;
  }

  /// A start time must be chosen.
  static String? startTime(ShadTimeOfDay? time) =>
      time == null ? startTimeRequiredMessage : null;
}
