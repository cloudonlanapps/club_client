import 'package:flutter/foundation.dart';

import 'eligibility_gender.dart';
import 'gender_eligibility_form_fields.dart';

/// Reads and seeds the gender field's entry in a form's flat value map.
///
/// The entry is a list of [EligibilityGender] in the order the boxes show;
/// an empty list is no gender criterion. The forms and their adapters go
/// through this class rather than spelling the key out.
class GenderEligibilityFormValues {
  const GenderEligibilityFormValues._();

  /// The field's entry for a form's initial values: [genders] in the order
  /// the boxes show, none ticked when left out.
  static Map<String, dynamic> initial([
    Iterable<EligibilityGender> genders = const [],
  ]) => {GenderEligibilityFormFields.gendersId: ordered(genders)};

  /// The genders [values] hold, in the order the boxes show; empty when they
  /// hold none. The entry is read as any list: `ShadForm.value` deep-copies
  /// the form's initial values, which turns a typed list into a
  /// `List<dynamic>`.
  static List<EligibilityGender> genders(Map<String, dynamic> values) =>
      ordered(
        (values[GenderEligibilityFormFields.gendersId] as List?)
                ?.whereType<EligibilityGender>() ??
            const [],
      );

  /// Whether [values] hold a gender criterion: at least one box ticked.
  static bool holdsValue(Map<String, dynamic> values) =>
      genders(values).isNotEmpty;

  /// [genders] once each, in the order the boxes show.
  static List<EligibilityGender> ordered(Iterable<EligibilityGender> genders) {
    final ticked = genders.toSet();
    return List.unmodifiable(EligibilityGender.values.where(ticked.contains));
  }

  /// Whether [a] and [b] differ, comparing their genders as sets, any other
  /// list entry by its elements and every other entry by `==`. `mapEquals`
  /// would compare a list by identity, and `ShadForm.value` hands back a
  /// copy of each, so the forms holding the field use this for `isDirty`.
  static bool differ(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (!setEquals(genders(a).toSet(), genders(b).toSet())) return true;
    final keys = {...a.keys, ...b.keys}
      ..remove(GenderEligibilityFormFields.gendersId);
    return keys.any((key) {
      final x = a[key];
      final y = b[key];
      if (x is List && y is List) return !listEquals(x, y);
      return x != y;
    });
  }
}
