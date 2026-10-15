import 'eligibility_gender.dart';
import 'gender_eligibility_form_values.dart';

/// The one place the gender criterion is written. The event editor, the
/// event preview, the group Eligibility section and the group card all read
/// it from here.
class GenderEligibilityText {
  const GenderEligibilityText._();

  /// Who the genders admit: "only for Boys" for one, "for Boys, Other and
  /// Prefer not to say" for several. `null` when there is no gender
  /// criterion.
  static String? phrase(Iterable<EligibilityGender> genders) {
    final names = [
      for (final gender in GenderEligibilityFormValues.ordered(genders))
        gender.label,
    ];
    if (names.isEmpty) return null;
    if (names.length == 1) return 'only for ${names.single}';
    final head = names.sublist(0, names.length - 1).join(', ');
    return 'for $head and ${names.last}';
  }

  /// The read views' sentence for a [subject] ("event", "group"): "This
  /// event is only for Boys." `null` when there is no gender criterion.
  static String? sentence(String subject, Iterable<EligibilityGender> genders) {
    final who = phrase(genders);
    return who == null ? null : 'This $subject is $who.';
  }

  /// The phrase as a line of its own, capitalised: "Only for Boys". `null`
  /// when there is no gender criterion.
  static String? line(Iterable<EligibilityGender> genders) {
    final who = phrase(genders);
    return who == null ? null : '${who[0].toUpperCase()}${who.substring(1)}';
  }
}
