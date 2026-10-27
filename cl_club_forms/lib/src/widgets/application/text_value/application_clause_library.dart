import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_clause_option.dart';
import '../../../models/application/application_language_option.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import 'application_clause_row.dart';

/// The library texts a section offers (club_client#336, #389, #396): the
/// club's texts of the section's kind, each a row showing its name and its
/// English text. Tapping one hands it, in the print [languages] only and
/// exactly as written, `{fact}` gaps included, to [onInsert], which puts
/// it at its one place. Nothing is filled: the PDF fills each gap from the
/// template's fact of that name.
class ApplicationClauseLibrary extends StatelessWidget {
  const ApplicationClauseLibrary({
    required this.clauses,
    required this.languages,
    required this.onInsert,
    this.enabled = true,
    super.key,
  });

  /// The texts offered, in the list's order.
  final List<ApplicationClauseOption> clauses;

  /// The print languages; the pasted text keeps these alone.
  final List<ApplicationLanguageOption> languages;

  /// Puts a pasted text in place.
  final ValueChanged<ApplicationClauseOption> onInsert;

  /// Whether the rows respond.
  final bool enabled;

  /// The texts of [kind] among [clauses], in the list's order.
  static List<ApplicationClauseOption> ofKind(
    List<ApplicationClauseOption> clauses,
    ApplicationClauseKind kind,
  ) => [
    for (final clause in clauses)
      if (clause.kind == kind) clause,
  ];

  /// [clause] as a row shows it: its heading, if any, and text, in English,
  /// or in its first language when it has no English.
  static String englishOf(ApplicationClauseOption clause) {
    const en = ApplicationFormFields.english;
    final text = clause.text[en] ?? clause.text.values.firstOrNull ?? clause.id;
    final heading = clause.heading[en] ?? clause.heading.values.firstOrNull;
    return heading == null ? text : '$heading — $text';
  }

  /// What an application list puts under its add button: the library's
  /// [clauses], each inserted as a new item made by [item]. Null, so
  /// nothing shows, with no text to offer.
  static Widget Function(ValueChanged<Object?> insert)? forItems({
    required List<ApplicationClauseOption> clauses,
    required List<ApplicationLanguageOption> languages,
    required bool enabled,
    required Object? Function(ApplicationClauseOption clause) item,
  }) {
    if (clauses.isEmpty) return null;
    return (insert) => ApplicationClauseLibrary(
      clauses: clauses,
      languages: languages,
      enabled: enabled,
      onInsert: (clause) => insert(item(clause)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final codes = [for (final language in languages) language.code];
    return LabeledFormRow(
      label: ApplicationFormStrings.library,
      field: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FormSpacing.labelGap,
        children: [
          Text(
            ApplicationFormStrings.libraryHint,
            style: theme.textTheme.muted,
          ),
          for (final clause in clauses)
            ApplicationClauseRow(
              key: ValueKey<String>(clause.id),
              text: englishOf(clause),
              name: clause.name,
              enabled: enabled,
              onTap: () => onInsert(clause.only(codes)),
            ),
        ],
      ),
    );
  }
}
