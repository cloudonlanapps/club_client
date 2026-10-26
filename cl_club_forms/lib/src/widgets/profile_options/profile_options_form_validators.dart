import '../../models/profile_label_language.dart';
import 'profile_options_form_fields.dart';
import 'profile_options_form_strings.dart';
import 'profile_options_form_values.dart';

/// Validators of `ProfileOptionsForm`'s two lists. Each returns `null`
/// when the list is valid, or the message of its first problem. Values and
/// names are compared trimmed and regardless of case.
abstract final class ProfileOptionsFormValidators {
  /// Every position has a value, no two the same, and a label in
  /// [ProfileOptionsFormFields.requiredLabelLanguage], named in the
  /// message by its entry in [labelLanguages].
  static String? Function(List<Object?>?) positions(
    List<ProfileLabelLanguage> labelLanguages,
  ) {
    const required = ProfileOptionsFormFields.requiredLabelLanguage;
    final requiredName = labelLanguages
        .where((language) => language.code == required)
        .map((language) => language.name)
        .firstOrNull;
    return (rows) {
      final seen = <String>{};
      for (final row in rows ?? const <Object?>[]) {
        final value = ProfileOptionsFormValues.valueOf(row);
        if (value.isEmpty) {
          return ProfileOptionsFormStrings.positionValueRequired;
        }
        if (!seen.add(value.toLowerCase())) {
          return ProfileOptionsFormStrings.positionValueTwice(value);
        }
        if (ProfileOptionsFormValues.labelOf(row, required).isEmpty) {
          return ProfileOptionsFormStrings.positionLabelRequired(
            requiredName ?? required,
          );
        }
      }
      return null;
    };
  }

  /// Every language has a name, no two the same.
  static String? languages(List<Object?>? names) {
    final seen = <String>{};
    for (final raw in names ?? const <Object?>[]) {
      final name = ProfileOptionsFormValues.text(raw).trim();
      if (name.isEmpty) return ProfileOptionsFormStrings.languageNameRequired;
      if (!seen.add(name.toLowerCase())) {
        return ProfileOptionsFormStrings.languageTwice(name);
      }
    }
    return null;
  }
}
