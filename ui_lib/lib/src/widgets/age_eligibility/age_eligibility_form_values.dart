import 'age_eligibility_form_fields.dart';
import 'form_age.dart';

/// Reads and seeds the age cluster's entries in a form's flat value map.
///
/// Each part of an age is its own text input, so the map holds six strings
/// and one bool. The forms' adapters go through this class in both
/// directions rather than spelling the keys out.
class AgeEligibilityFormValues {
  const AgeEligibilityFormValues._();

  /// The cluster's entries for a form's initial values: every part as text
  /// (`''` when the bound is not set) so the forms' `isDirty` compares
  /// cleanly.
  static Map<String, dynamic> initial({
    FormAge? minAge,
    FormAge? maxAge,
    bool strictAge = false,
  }) {
    return {
      AgeEligibilityFormFields.minAgeYearsId: yearsText(minAge),
      AgeEligibilityFormFields.minAgeMonthsId: partText(minAge?.months),
      AgeEligibilityFormFields.minAgeDaysId: partText(minAge?.days),
      AgeEligibilityFormFields.maxAgeYearsId: yearsText(maxAge),
      AgeEligibilityFormFields.maxAgeMonthsId: partText(maxAge?.months),
      AgeEligibilityFormFields.maxAgeDaysId: partText(maxAge?.days),
      AgeEligibilityFormFields.strictAgeId: strictAge,
    };
  }

  /// The minimum age the form holds, or `null` when its three inputs are
  /// empty.
  static FormAge? minAge(Map<String, dynamic> values) =>
      age(values, AgeEligibilityFormFields.minAgeIds);

  /// The maximum age the form holds, or `null` when its three inputs are
  /// empty.
  static FormAge? maxAge(Map<String, dynamic> values) =>
      age(values, AgeEligibilityFormFields.maxAgeIds);

  /// Whether the Strict age check is ticked.
  static bool strictAge(Map<String, dynamic> values) =>
      values[AgeEligibilityFormFields.strictAgeId] as bool? ?? false;

  /// Whether the form holds a minimum or a maximum age.
  static bool hasAgeBound(Map<String, dynamic> values) =>
      minAge(values) != null || maxAge(values) != null;

  /// The age held by the three inputs [ids] (years, months, days). All
  /// three empty is no bound; an empty part of a set age counts as zero.
  static FormAge? age(Map<String, dynamic> values, List<String> ids) {
    final parts = [for (final id in ids) text(values[id])];
    if (parts.every((p) => p.isEmpty)) return null;
    return FormAge(
      years: int.tryParse(parts[0]) ?? 0,
      months: int.tryParse(parts[1]) ?? 0,
      days: int.tryParse(parts[2]) ?? 0,
    );
  }

  /// A raw input value as trimmed text (`null` reads as empty).
  static String text(Object? raw) => (raw as String?)?.trim() ?? '';

  /// The years of [age] as the text its input shows: always a number for a
  /// set age, so a set age is never three empty inputs.
  static String yearsText(FormAge? age) => age == null ? '' : '${age.years}';

  /// The months or days of an age as the text its input shows: empty when
  /// zero, like a part the user never filled.
  static String partText(int? part) =>
      (part == null || part == 0) ? '' : '$part';
}
