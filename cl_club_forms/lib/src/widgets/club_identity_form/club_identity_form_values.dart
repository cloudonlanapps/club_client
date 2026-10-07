import 'package:cl_club_forms/src/models/form_translated_text.dart';

import 'translated_text_inputs.dart';

/// How the club identity section forms (`ClubDetailsForm`, `ClubContactForm`,
/// `ClubAddressForm`) turn their values into form fields and back.
///
/// A host speaks one value per field: a `String` for a plain text field, a
/// [FormTranslatedText] for a translatable one. Inside the `ShadForm` every
/// input is its own field: a translatable field is its default text under
/// its id plus one field per language
/// ([TranslatedTextInputs.translationIdOf]).
abstract final class ClubIdentityFormValues {
  /// The value of the translatable field [id] in [values]; missing reads
  /// empty.
  static FormTranslatedText translatedOf(
    Map<String, dynamic> values,
    String id,
  ) => values[id] as FormTranslatedText? ?? const FormTranslatedText('');

  /// The `ShadForm`'s initial value: [values] with every translatable field
  /// spread over its default and one field per language of [languages].
  static Map<String, dynamic> spread({
    required Map<String, dynamic> values,
    required List<String> textIds,
    required List<String> translatedIds,
    required List<String> languages,
  }) => {
    for (final id in textIds) id: values[id] as String? ?? '',
    for (final id in translatedIds) ...{
      id: translatedOf(values, id).defaultValue,
      for (final language in languages)
        TranslatedTextInputs.translationIdOf(id, language):
            translatedOf(values, id).byLanguage[language] ?? '',
    },
  };

  /// The values a host reads, from the `ShadForm`'s [raw] field map: every
  /// text trimmed, every translatable field gathered back into a
  /// [FormTranslatedText] with its empty translations dropped.
  ///
  /// A translation that [initialValues] carries in a language the form does
  /// not offer ([languages]) has no input, and is kept as it was.
  static Map<String, dynamic> gather({
    required Map<String, dynamic> raw,
    required Map<String, dynamic> initialValues,
    required List<String> textIds,
    required List<String> translatedIds,
    required List<String> languages,
  }) => {
    for (final id in textIds) id: (raw[id] as String? ?? '').trim(),
    for (final id in translatedIds)
      id: FormTranslatedText(raw[id] as String? ?? '', {
        for (final entry in translatedOf(initialValues, id).byLanguage.entries)
          if (!languages.contains(entry.key)) entry.key: entry.value,
        for (final language in languages)
          language:
              raw[TranslatedTextInputs.translationIdOf(id, language)]
                  as String? ??
              '',
      }).trimmed(),
  };

  /// The message for the first translatable field of [gathered] that has a
  /// translation but no default text, named by its label in [labels]; null
  /// when every field with a translation has its default.
  static String? missingDefaultError({
    required Map<String, dynamic> gathered,
    required List<String> translatedIds,
    required Map<String, String> labels,
  }) {
    for (final id in translatedIds) {
      final value = translatedOf(gathered, id);
      if (value.defaultValue.isEmpty && value.byLanguage.isNotEmpty) {
        return '${labels[id]} has a translation but no default text.';
      }
    }
    return null;
  }
}
