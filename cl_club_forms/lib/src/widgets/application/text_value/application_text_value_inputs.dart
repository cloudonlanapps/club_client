import 'package:flutter/material.dart';

import '../../form/labeled_form_row.dart';
import '../application_form_strings.dart';
import '../application_text_mode.dart';
import 'application_clause_picker.dart';
import 'application_custom_text_inputs.dart';
import 'application_fact_picker.dart';
import 'application_text_value_editor.dart';

/// The inputs of a printed text for its mode, which edit what [editor]
/// holds: an input per print language, a fact, or a clause and the facts
/// of its gaps.
class ApplicationTextValueInputs extends StatelessWidget {
  const ApplicationTextValueInputs({required this.editor, super.key});

  /// The text's editor, which holds the values and reports them.
  final ApplicationTextValueEditorState editor;

  @override
  Widget build(BuildContext context) {
    final e = editor;
    final w = e.widget;
    return switch (e.mode) {
      ApplicationTextMode.custom => ApplicationCustomTextInputs(
        languages: w.languages,
        controllers: {
          for (final language in w.languages)
            language.code: e.controllerOf(language.code),
        },
        enabled: w.enabled,
        requireEnglish: w.requireEnglish,
        multiline: w.multiline,
        label: w.label,
        onChanged: e.report,
      ),
      ApplicationTextMode.fact => LabeledFormRow(
        label: ApplicationFormStrings.fact,
        field: ApplicationFactPicker(
          facts: w.sources.facts,
          value: e.fact,
          enabled: w.enabled,
          onChanged: (name) => e.update(() => e.fact = name),
        ),
      ),
      ApplicationTextMode.clause => ApplicationClausePicker(
        clauses: w.sources.clausesOf(w.clauseKind),
        sources: w.sources,
        clause: e.clause,
        args: e.args,
        enabled: w.enabled,
        onClauseChanged: e.pickClause,
        onArgChanged: (gap, name) => e.update(() => e.args[gap] = name),
      ),
    };
  }
}
