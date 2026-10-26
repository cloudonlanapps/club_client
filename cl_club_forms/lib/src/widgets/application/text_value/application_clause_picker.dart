import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_option.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import '../application_text_sources.dart';
import 'application_fact_picker.dart';

/// A clause of the library with its gaps bound to facts: a select of the
/// clauses offered, each shown by its English text with its gaps, the
/// chosen one's text in full, and for each of its gaps a select of the
/// template's facts of the gap's type.
class ApplicationClausePicker extends StatelessWidget {
  const ApplicationClausePicker({
    required this.clauses,
    required this.sources,
    required this.clause,
    required this.args,
    required this.enabled,
    required this.onClauseChanged,
    required this.onArgChanged,
    super.key,
  });

  /// The clauses offered, in order.
  final List<ApplicationClauseOption> clauses;

  /// The template's facts, for the gaps.
  final ApplicationTextSources sources;

  /// The chosen clause's id; `''` for none.
  final String clause;

  /// The fact bound to each gap, by gap name.
  final Map<String, String> args;

  /// Whether the selects respond.
  final bool enabled;

  /// Called with the chosen clause's id.
  final ValueChanged<String> onClauseChanged;

  /// Called with a gap and the fact chosen for it.
  final void Function(String gap, String fact) onArgChanged;

  /// The English text a clause is shown by: a rule's heading, then its
  /// text.
  static String englishOf(ApplicationClauseOption clause) {
    const en = ApplicationFormFields.english;
    final text = clause.text[en] ?? clause.id;
    final heading = clause.heading[en];
    return heading == null ? text : '$heading — $text';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final chosen = sources.clauses[clause];
    final shown = {for (final option in clauses) option.id: englishOf(option)};
    if (clause.isNotEmpty && !shown.containsKey(clause)) shown[clause] = clause;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.rowGap,
      children: [
        LabeledFormRow(
          label: ApplicationFormStrings.clause,
          field: ShadSelect<String>(
            initialValue: clause.isEmpty ? null : clause,
            enabled: enabled,
            placeholder: const Text(ApplicationFormStrings.chooseClauseHint),
            options: [
              for (final entry in shown.entries)
                ShadOption(value: entry.key, child: Text(entry.value)),
            ],
            selectedOptionBuilder: (context, id) => Text(
              shown[id] ?? id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onChanged: (id) {
              if (id != null) onClauseChanged(id);
            },
          ),
        ),
        if (chosen != null)
          Text(englishOf(chosen), style: theme.textTheme.muted),
        if (chosen != null)
          for (final MapEntry(key: gap, value: type) in chosen.gaps.entries)
            LabeledFormRow(
              key: ValueKey<String>('$clause/$gap'),
              label: ApplicationFormStrings.gapLabel(gap, type),
              field: ApplicationFactPicker(
                facts: {for (final name in sources.factsOf(type)) name: type},
                value: args[gap] ?? '',
                enabled: enabled,
                onChanged: (fact) => onArgChanged(gap, fact),
              ),
            ),
      ],
    );
  }
}
