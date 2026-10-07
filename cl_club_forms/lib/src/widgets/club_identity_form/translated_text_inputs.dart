import 'package:flutter/material.dart';

import '../../constants/form_spacing.dart';
import 'club_identity_text_input.dart';

/// A translatable field of a club identity section form: the default text,
/// then one input per language in [languages]. Each input is its own form
/// field — `<id>` for the default and `<id>@<language>` for a translation
/// (see [translationIdOf]); the form gathers them into a
/// `FormTranslatedText`.
class TranslatedTextInputs extends StatelessWidget {
  const TranslatedTextInputs({
    required this.id,
    required this.label,
    required this.languages,
    this.keyboardType = TextInputType.text,
    this.multiline = false,
    super.key,
  });

  /// Separates a field id from a language code in a translation's field id.
  /// Not `.`, which `ShadForm` reads as nesting.
  static const String languageSeparator = '@';

  /// Help under the default input when translations are offered.
  static const String defaultHelp = 'Default, for any language';

  /// How far a translation's input is set in from the default's.
  static const double translationIndent = 16;

  /// The form field id of [id]'s translation in [language].
  static String translationIdOf(String id, String language) =>
      '$id$languageSeparator$language';

  /// The form field id of the default text.
  final String id;

  /// The label of the default input; a translation's adds its language.
  final String label;

  /// The language codes to offer a translation in.
  final List<String> languages;

  /// The keyboard every input asks for.
  final TextInputType keyboardType;

  /// Two to four lines per input instead of one.
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.rowGap,
      children: [
        ClubIdentityTextInput(
          id: id,
          label: label,
          keyboardType: keyboardType,
          multiline: multiline,
          description: languages.isEmpty ? null : defaultHelp,
        ),
        for (final language in languages)
          Padding(
            padding: const EdgeInsets.only(left: translationIndent),
            child: ClubIdentityTextInput(
              id: translationIdOf(id, language),
              label: '$label ($language)',
              keyboardType: keyboardType,
              multiline: multiline,
            ),
          ),
      ],
    );
  }
}
