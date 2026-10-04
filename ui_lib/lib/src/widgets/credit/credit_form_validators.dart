/// Validators shared by the credit forms (club_core#101). SDK-free.
class CreditFormValidators {
  const CreditFormValidators._();

  /// A whole number of credits, at least [min], at most [max] when given.
  static String? credits(String value, {int min = 1, int? max}) {
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a whole number';
    if (n < min) return 'At least $min';
    if (max != null && n > max) return 'At most $max';
    return null;
  }

  /// Every credit action records why it was taken.
  static String? reason(String value) =>
      value.trim().isEmpty ? 'A reason is required' : null;

  /// A date that must be picked.
  static String? requiredDate(DateTime? value) =>
      value == null ? 'Pick a date' : null;

  /// The cross-field rule of a validity window, checked on submit: it ends on
  /// or after it starts, and not before [today]. Returns the inline message,
  /// or null when the window is valid.
  static String? window({
    required DateTime from,
    required DateTime until,
    required DateTime today,
  }) {
    if (until.isBefore(from)) return 'Valid until must not be before from';
    if (until.isBefore(DateTime(today.year, today.month, today.day))) {
      return 'Valid until must not be in the past';
    }
    return null;
  }
}
