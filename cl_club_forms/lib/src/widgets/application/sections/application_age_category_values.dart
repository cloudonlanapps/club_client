import '../../../models/application/application_custom_text.dart';
import '../application_form_fields.dart';

/// Reads and shapes an age category of an application as the template
/// holds it.
abstract final class ApplicationAgeCategoryValues {
  /// The genders a category may take, as the template stores them.
  static const List<String> genders = ['male', 'female', 'other'];

  /// [json], an age category, as the form holds and returns it: its name
  /// per language, notes and empty texts left out; whether it has an age
  /// limit (given, or else whether it has a birth date); its birth dates
  /// only while it has one; its genders only when it has them.
  static Map<String, Object?> category(Object? json) {
    final map = json is Map ? json : const <Object?, Object?>{};
    final after = map[ApplicationFormFields.bornOnOrAfterKey];
    final before = map[ApplicationFormFields.bornOnOrBeforeKey];
    final limit = map[ApplicationFormFields.ageLimitKey];
    final ticked = map[ApplicationFormFields.gendersKey];
    return build(
      label: ApplicationCustomText.fromJson(
        map[ApplicationFormFields.labelKey],
      ).text,
      ageLimit: limit is bool ? limit : after is String || before is String,
      bornOnOrAfter: after is String ? after : '',
      bornOnOrBefore: before is String ? before : '',
      genders: [if (ticked is List) ...ticked.whereType<String>()],
    );
  }

  /// An age category of [label], with an age limit or not, birth dates
  /// (`''` for none; left out without [ageLimit]) and [genders] (empty
  /// for all).
  static Map<String, Object?> build({
    required Map<String, String> label,
    required bool ageLimit,
    required String bornOnOrAfter,
    required String bornOnOrBefore,
    required List<String> genders,
  }) => {
    ApplicationFormFields.labelKey: label,
    ApplicationFormFields.ageLimitKey: ageLimit,
    if (ageLimit && bornOnOrAfter.isNotEmpty)
      ApplicationFormFields.bornOnOrAfterKey: bornOnOrAfter,
    if (ageLimit && bornOnOrBefore.isNotEmpty)
      ApplicationFormFields.bornOnOrBeforeKey: bornOnOrBefore,
    if (genders.isNotEmpty) ApplicationFormFields.gendersKey: genders,
  };
}
