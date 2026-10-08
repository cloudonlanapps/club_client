import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

/// Pure validators for the inputs of a programme's schedule
/// (`ProgrammeScheduleFormField`, shown by `ProgrammeScheduleAdjustForm`
/// and by `EventCreateForm`).
class ProgrammeScheduleFormValidators {
  const ProgrammeScheduleFormValidators._();

  /// Shown when no weekday is picked.
  static const String weekdaysRequiredMessage = 'Pick at least one day';

  /// Shown when no start date is chosen.
  static const String startDateRequiredMessage = 'Start date is required';

  /// Shown when no start time is chosen.
  static const String startTimeRequiredMessage = 'Start time is required';

  /// At least one weekday must be picked.
  static String? weekdays(Set<int>? days) =>
      (days == null || days.isEmpty) ? weekdaysRequiredMessage : null;

  /// A start date must be chosen.
  static String? startDate(DateTime? date) =>
      date == null ? startDateRequiredMessage : null;

  /// A start time must be chosen.
  static String? startTime(ShadTimeOfDay? time) =>
      time == null ? startTimeRequiredMessage : null;
}
