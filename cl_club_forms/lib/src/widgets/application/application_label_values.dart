import 'package:flutter/foundation.dart';

import '../../models/application/application_label_option.dart';
import '../../models/application/application_language_option.dart';
import '../../models/application/application_texts.dart';
import 'application_form_fields.dart';

/// Reads and shapes the label overrides of an application: the catalogue
/// merged with the template's overrides becomes the text of each label's
/// input, and the inputs become the overrides again.
abstract final class ApplicationLabelValues {
  /// The template's overrides in [json], by label id, notes left out.
  static Map<String, Map<String, String>> overrides(Object? json) => {
    if (json is Map)
      for (final entry in json.entries)
        if (entry.key case final String id when !id.startsWith('_'))
          id: ApplicationTexts.of(entry.value),
  };

  /// The text of each input, by field id: the override of a label where it
  /// has one, else the catalogue's.
  static Map<String, String> inputs(
    List<ApplicationLabelOption> labels,
    List<ApplicationLanguageOption> languages,
    Map<String, Map<String, String>> overrides,
  ) => {
    for (final label in labels)
      for (final language in languages)
        ApplicationFormFields.labelFieldId(label.id, language.code):
            overrides[label.id]?[language.code] ??
            label.text[language.code] ??
            '',
  };

  /// The overrides [values] (the inputs, by field id) make: a label whose
  /// texts differ from the catalogue's, with all its languages (the
  /// catalogue's, then the earlier override's, then the inputs'). An
  /// override of a label the catalogue no longer has is kept.
  static Map<String, Map<String, String>> overridesOut(
    Map<String, dynamic> values,
    List<ApplicationLabelOption> labels,
    List<ApplicationLanguageOption> languages,
    Map<String, Map<String, String>> overrides,
  ) {
    final known = {for (final label in labels) label.id};
    return {
      for (final entry in overrides.entries)
        if (!known.contains(entry.key)) entry.key: entry.value,
      for (final label in labels)
        if (merged(values, label, languages, overrides[label.id])
            case final Map<String, String> texts
            when !mapEquals(texts, label.text))
          label.id: texts,
    };
  }

  /// [label]'s texts after [values]: the catalogue's, then [override]'s,
  /// then each input's, trimmed.
  static Map<String, String> merged(
    Map<String, dynamic> values,
    ApplicationLabelOption label,
    List<ApplicationLanguageOption> languages,
    Map<String, String>? override,
  ) => {
    ...label.text,
    ...?override,
    for (final language in languages)
      language.code:
          (values[ApplicationFormFields.labelFieldId(label.id, language.code)]
                      as String? ??
                  '')
              .trim(),
  };
}
