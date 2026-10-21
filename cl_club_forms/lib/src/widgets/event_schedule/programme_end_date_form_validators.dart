/// Pure validators for `ProgrammeEndDateForm`.
class ProgrammeEndDateFormValidators {
  const ProgrammeEndDateFormValidators._();

  /// The longest reason the server accepts.
  static const int reasonMaxLength = 500;

  /// Shown when no day is chosen.
  static const String dayRequiredMessage = 'Pick the last day';

  /// Shown when the chosen day is before today.
  static const String dayInPastMessage = 'The end date cannot be before today';

  /// Shown when the chosen day is before the day proposed, itself before
  /// today (ending a programme from a session later today).
  static const String dayBeforeProposedMessage =
      'The end date cannot be before the day proposed';

  /// Shown when a reason is needed and none is given.
  static const String reasonRequiredMessage = 'Say why the programme is ending';

  /// Shown when the reason is longer than [reasonMaxLength].
  static const String reasonTooLongMessage =
      'Keep the reason within $reasonMaxLength characters';

  /// The last day must be chosen and may be any day from [today] on, or
  /// from [earliest] when that is an earlier day (club_client#182).
  static String? lastDay(
    DateTime? day, {
    DateTime? today,
    DateTime? earliest,
  }) {
    if (day == null) return dayRequiredMessage;
    final now = today ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final proposed = earliest == null
        ? null
        : DateTime(earliest.year, earliest.month, earliest.day);
    final first = proposed != null && proposed.isBefore(todayStart)
        ? proposed
        : todayStart;
    final chosen = DateTime(day.year, day.month, day.day);
    if (!chosen.isBefore(first)) return null;
    return first == todayStart ? dayInPastMessage : dayBeforeProposedMessage;
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
