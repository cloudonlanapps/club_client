import '../../../models/application/application_custom_text.dart';
import '../application_form_fields.dart';

/// Reads and shapes an age category of an application as the template
/// holds it.
abstract final class ApplicationAgeCategoryValues {
  /// The genders a category may take, as the template stores them.
  static const List<String> genders = ['male', 'female', 'other'];

  /// [json], an age category, as the form holds and returns it: its name
  /// per language, notes and empty texts left out; its birth dates and
  /// genders only when it has them.
  static Map<String, Object?> category(Object? json) {
    final map = json is Map ? json : const <Object?, Object?>{};
    final after = map[ApplicationFormFields.bornOnOrAfterKey];
    final before = map[ApplicationFormFields.bornOnOrBeforeKey];
    final ticked = map[ApplicationFormFields.gendersKey];
    return build(
      label: ApplicationCustomText.fromJson(
        map[ApplicationFormFields.labelKey],
      ).text,
      bornOnOrAfter: after is String ? after : '',
      bornOnOrBefore: before is String ? before : '',
      genders: [if (ticked is List) ...ticked.whereType<String>()],
    );
  }

  /// An age category of [label], birth dates (`''` for none) and
  /// [genders] (empty for all).
  static Map<String, Object?> build({
    required Map<String, String> label,
    required String bornOnOrAfter,
    required String bornOnOrBefore,
    required List<String> genders,
  }) => {
    ApplicationFormFields.labelKey: label,
    if (bornOnOrAfter.isNotEmpty)
      ApplicationFormFields.bornOnOrAfterKey: bornOnOrAfter,
    if (bornOnOrBefore.isNotEmpty)
      ApplicationFormFields.bornOnOrBeforeKey: bornOnOrBefore,
    if (genders.isNotEmpty) ApplicationFormFields.gendersKey: genders,
  };
}
