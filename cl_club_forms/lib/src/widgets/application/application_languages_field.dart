import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_language_option.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';

/// The print languages of an application: English only, or English and one
/// other of [options]. The field holds the other language's code, `''` for
/// none; its form returns the template's `languages` list.
///
/// Sits inside the embedding form's `ShadForm`, which holds the value.
class ApplicationLanguagesField extends StatelessWidget {
  const ApplicationLanguagesField({
    required this.options,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The languages of the label catalogue; English among them is not
  /// offered as the other.
  final List<ApplicationLanguageOption> options;

  /// Whether the field responds.
  final bool enabled;

  /// Called with the other language picked.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final shown = {
      '': ApplicationFormStrings.englishOnly,
      for (final option in options)
        if (option.code != ApplicationFormFields.english)
          option.code: ApplicationFormStrings.englishAnd(option.name),
    };
    return ShadSelectFormField<String>(
      id: ApplicationFormFields.languagesId,
      enabled: enabled,
      options: [
        for (final entry in shown.entries)
          ShadOption(value: entry.key, child: Text(entry.value)),
      ],
      selectedOptionBuilder: (context, code) => Text(shown[code] ?? code),
      onChanged: (code) => onChanged?.call(code ?? ''),
    );
  }
}
