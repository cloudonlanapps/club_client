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

  /// A language code as the server takes one (club_server#133):
  /// `mr`, `kok`, `pt-br`, `x-<name>`; `x` alone is not one.
  static final RegExp languageCode = RegExp(
    r'^(?:[a-z]{2,3}|x)(?:-[a-z0-9]{1,8})*$',
  );

  /// Every language has a name and a language code, no two names and no
  /// two codes the same (club_client#396).
  static String? languages(List<Object?>? rows) {
    final names = <String>{};
    final codes = <String>{};
    for (final l in ProfileOptionsFormValues.languagesOut(rows)) {
      final name = l[ProfileOptionsFormFields.nameKey]!;
      final code = l[ProfileOptionsFormFields.codeKey]!;
      if (name.isEmpty) return ProfileOptionsFormStrings.languageNameRequired;
      if (!names.add(name.toLowerCase())) {
        return ProfileOptionsFormStrings.languageTwice(name);
      }
      if (code.isEmpty) return ProfileOptionsFormStrings.languageCodeRequired;
      if (code == 'x' || !languageCode.hasMatch(code)) {
        return ProfileOptionsFormStrings.languageCodeInvalid(code);
      }
      if (!codes.add(code)) {
        return ProfileOptionsFormStrings.languageCodeTwice(code);
      }
    }
    return null;
  }
}
