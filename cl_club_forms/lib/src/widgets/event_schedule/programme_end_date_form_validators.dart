/// Pure validators for `ProgrammeEndDateForm`.
class ProgrammeEndDateFormValidators {
  const ProgrammeEndDateFormValidators._();

  /// The longest reason the server accepts.
  static const int reasonMaxLength = 500;

  /// Shown when no day is chosen.
  static const String dayRequiredMessage = 'Pick the last day';

  /// Shown when the chosen day is before today.
  static const String dayInPastMessage = 'The end date cannot be before today';

  /// Shown when a reason is needed and none is given.
  static const String reasonRequiredMessage = 'Say why the programme is ending';

  /// Shown when the reason is longer than [reasonMaxLength].
  static const String reasonTooLongMessage =
      'Keep the reason within $reasonMaxLength characters';

  /// The last day must be chosen and may be any day from [today] on.
  static String? lastDay(DateTime? day, {DateTime? today}) {
    if (day == null) return dayRequiredMessage;
    final now = today ?? DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final chosen = DateTime(day.year, day.month, day.day);
    return chosen.isBefore(first) ? dayInPastMessage : null;
  }

  /// A reason is needed when [required], and is never longer than
  /// [reasonMaxLength].
  static String? reason(String? value, {required bool required}) {
    final text = (value ?? '').trim();
    if (required && text.isEmpty) return reasonRequiredMessage;
    if (text.length > reasonMaxLength) return reasonTooLongMessage;
    return null;
  }
}
