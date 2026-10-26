import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_choice_option.dart';
import '../../../models/application/application_fact_type.dart';
import '../../../models/application/application_language_option.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_strings.dart';
import '../application_text_mode.dart';
import '../application_text_sources.dart';
import '../text_value/application_text_value_editor.dart';
import 'application_choices_input.dart';
import 'application_date_input.dart';
import 'application_fact_editor.dart';
import 'application_time_input.dart';

/// The inputs of a fact's value for its type, which edit what [editor]
/// holds: a name in each print language, a day, a first and a last day, a
/// time, an amount or the choices ticked.
class ApplicationFactValueInputs extends StatelessWidget {
  const ApplicationFactValueInputs({
    required this.editor,
    required this.languages,
    required this.choices,
    required this.enabled,
    super.key,
  });

  /// The fact's editor, which holds the values and reports them.
  final ApplicationFactEditorState editor;

  /// The print languages a name may be given in.
  final List<ApplicationLanguageOption> languages;

  /// The library's choices.
  final List<ApplicationChoiceOption> choices;

  /// Whether the inputs respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final e = editor;
    LabeledFormRow date(String label, String value, ValueChanged<String> set) =>
        LabeledFormRow(
          label: label,
          field: ApplicationDateInput(
            value: value,
            enabled: enabled,
            onChanged: (day) => e.update(() => set(day)),
          ),
        );
    return switch (e.type) {
      ApplicationFactType.name => ApplicationTextValueEditor(
        modes: const [ApplicationTextMode.custom],
        languages: languages,
        sources: ApplicationTextSources(),
        requireEnglish: true,
        initialValue: e.nameValue,
        enabled: enabled,
        onChanged: (value) => e.update(() => e.nameValue = value),
      ),
      ApplicationFactType.date => date(
        ApplicationFormStrings.day,
        e.day,
        (day) => e.day = day,
      ),
      ApplicationFactType.dateRange => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FormSpacing.rowGap,
        children: [
          date(ApplicationFormStrings.from, e.from, (day) => e.from = day),
          date(ApplicationFormStrings.to, e.to, (day) => e.to = day),
        ],
      ),
      ApplicationFactType.time => LabeledFormRow(
        label: ApplicationFormStrings.time,
        field: ApplicationTimeInput(controller: e.time, enabled: enabled),
      ),
      ApplicationFactType.amount => LabeledFormRow(
        label: ApplicationFormStrings.amount,
        field: ShadInput(
          controller: e.amount,
          enabled: enabled,
          keyboardType: TextInputType.number,
          onChanged: (_) => e.report(),
        ),
      ),
      ApplicationFactType.choices => LabeledFormRow(
        label: ApplicationFormStrings.choices,
        field: ApplicationChoicesInput(
          options: choices,
          value: e.choices,
          enabled: enabled,
          onChanged: (ticked) => e.update(() => e.choices = ticked),
        ),
      ),
    };
  }
}
