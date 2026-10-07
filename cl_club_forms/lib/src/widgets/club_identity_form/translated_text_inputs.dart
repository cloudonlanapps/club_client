import 'package:cl_club_forms/src/models/form_translated_text.dart';
import 'package:flutter/material.dart';

import 'club_identity_text_input.dart';

/// A translatable field of `ClubIdentityForm`: the default text, then one
/// input per language in [languages]. Each input is its own form field —
/// `<id>` for the default and `<id>@<language>` for a variant (see
/// [translationIdOf]); the form assembles them into a [FormTranslatedText].
class TranslatedTextInputs extends StatelessWidget {
  const TranslatedTextInputs({
    required this.id,
    required this.label,
    required this.initialValue,
    required this.languages,
    this.keyboardType = TextInputType.text,
    this.multiline = false,
    super.key,
  });

  /// Separates a field id from a language code in a variant's field id. Not
  /// `.`, which `ShadForm` reads as nesting.
  static const String languageSeparator = '@';

  /// The form field id of [id]'s variant in [language].
  static String translationIdOf(String id, String language) =>
      '$id$languageSeparator$language';

  final String id;
  final String label;
  final FormTranslatedText initialValue;
  final List<String> languages;
  final TextInputType keyboardType;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        ClubIdentityTextInput(
          id: id,
          label: label,
          initialValue: initialValue.defaultValue,
          keyboardType: keyboardType,
          multiline: multiline,
          description: languages.isEmpty ? null : 'Default, for any language',
        ),
        for (final language in languages)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ClubIdentityTextInput(
              id: translationIdOf(id, language),
              label: '$label ($language)',
              initialValue: initialValue.byLanguage[language] ?? '',
              keyboardType: keyboardType,
              multiline: multiline,
            ),
          ),
      ],
    );
  }
}
