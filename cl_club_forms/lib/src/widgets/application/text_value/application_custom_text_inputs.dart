import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_language_option.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_fields.dart';

/// A custom text of an application: one input per print language, each
/// labelled with the language's name, typed into its controller.
class ApplicationCustomTextInputs extends StatelessWidget {
  const ApplicationCustomTextInputs({
    required this.languages,
    required this.controllers,
    required this.enabled,
    required this.onChanged,
    this.requireEnglish = false,
    this.multiline = false,
    this.label,
    super.key,
  });

  /// The lines a multi-line input shows at least.
  static const int minLines = 2;

  /// The lines a multi-line input grows to.
  static const int maxLines = 5;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The text of each language, by code; one for each of [languages].
  final Map<String, TextEditingController> controllers;

  /// Whether the inputs respond.
  final bool enabled;

  /// Called after any input changes.
  final VoidCallback onChanged;

  /// Whether the English input is marked required.
  final bool requireEnglish;

  /// Several lines per input instead of one.
  final bool multiline;

  /// What the text is, put before each language's name (`Heading`).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final prefix = label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.rowGap,
      children: [
        for (final language in languages)
          LabeledFormRow(
            label: prefix == null
                ? language.name
                : '$prefix (${language.name})',
            required:
                requireEnglish &&
                language.code == ApplicationFormFields.english,
            field: ShadInput(
              controller: controllers[language.code],
              enabled: enabled,
              keyboardType: multiline
                  ? TextInputType.multiline
                  : TextInputType.text,
              minLines: multiline ? minLines : null,
              maxLines: multiline ? maxLines : 1,
              onChanged: (_) => onChanged(),
            ),
          ),
      ],
    );
  }
}
