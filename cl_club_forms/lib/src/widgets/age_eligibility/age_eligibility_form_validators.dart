import 'age_eligibility_form_fields.dart';
import 'age_eligibility_form_values.dart';

/// Static validators for the shared age cluster. The limits are the
/// server's: years 0–150, months 0–11, days 0–30.
class AgeEligibilityFormValidators {
  const AgeEligibilityFormValidators._();

  static const int maxYears = 150;
  static const int maxMonths = 11;
  static const int maxDays = 30;

  static const String yearsMessage = 'Years must be between 0 and $maxYears.';
  static const String monthsMessage =
      'Months must be between 0 and $maxMonths.';
  static const String daysMessage = 'Days must be between 0 and $maxDays.';
  static const String bandMessage =
      'Minimum age must not be greater than maximum age.';

  /// Cross-field check of the whole band, for a form's `validate()`: every
  /// part within its limit, and the minimum not above the maximum. Returns
  /// the message to show inline, or `null` when the band is valid.
  static String? band(Map<String, dynamic> values) {
    for (final ids in [
      AgeEligibilityFormFields.minAgeIds,
      AgeEligibilityFormFields.maxAgeIds,
    ]) {
      final error =
          part(values[ids[0]], max: maxYears, message: yearsMessage) ??
          part(values[ids[1]], max: maxMonths, message: monthsMessage) ??
          part(values[ids[2]], max: maxDays, message: daysMessage);
      if (error != null) return error;
    }
    final min = AgeEligibilityFormValues.minAge(values);
    final max = AgeEligibilityFormValues.maxAge(values);
    if (min != null && max != null && min.compareTo(max) > 0) {
      return bandMessage;
    }
    return null;
  }

  /// One input: empty, or a whole number from 0 to [max]; otherwise
  /// [message].
  static String? part(
    Object? raw, {
    required int max,
    required String message,
  }) {
    final text = AgeEligibilityFormValues.text(raw);
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    if (number == null || number < 0 || number > max) return message;
    return null;
  }
}
