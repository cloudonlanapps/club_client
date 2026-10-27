import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_fill.dart';
import '../../../models/application/application_clause_option.dart';
import '../../../models/application/application_fact_type.dart';
import '../../../models/application/application_language_option.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_strings.dart';
import 'application_clause_picker.dart';

/// The library clauses a section offers (club_client#336): each a row
/// showing its English text. Tapping one fills it with the template's
/// facts through [fill] and hands the filled text, in the print
/// [languages] only, to [onInsert], which puts it at its one place.
///
/// A gap no fact fills is said under the list without a call; a fill the
/// host refuses is said there too, and nothing is inserted. The rows do
/// not respond while a fill is in flight.
class ApplicationClauseLibrary extends StatefulWidget {
  const ApplicationClauseLibrary({
    required this.clauses,
    required this.facts,
    required this.languages,
    required this.fill,
    required this.onInsert,
    this.enabled = true,
    super.key,
  });

  /// The clauses offered, in the library's order.
  final List<ApplicationClauseOption> clauses;

  /// The template's facts: the type of each, by name.
  final Map<String, ApplicationFactType> facts;

  /// The print languages; the filled text keeps these alone.
  final List<ApplicationLanguageOption> languages;

  /// Fills a clause (the host's call).
  final ApplicationClauseFiller fill;

  /// Puts a filled clause in place.
  final ValueChanged<ApplicationClauseFilled> onInsert;

  /// Whether the rows respond.
  final bool enabled;

  /// What an application list puts under its add button: the library's
  /// [clauses], each inserted as a new item made by [item]. Null, so
  /// nothing shows, without [fill] or with no clause to offer.
  static Widget Function(ValueChanged<Object?> insert)? forItems({
    required List<ApplicationClauseOption> clauses,
    required Map<String, ApplicationFactType> facts,
    required List<ApplicationLanguageOption> languages,
    required ApplicationClauseFiller? fill,
    required bool enabled,
    required Object? Function(ApplicationClauseFilled filled) item,
  }) {
    if (fill == null || clauses.isEmpty) return null;
    return (insert) => ApplicationClauseLibrary(
      clauses: clauses,
      facts: facts,
      languages: languages,
      fill: fill,
      enabled: enabled,
      onInsert: (filled) => insert(item(filled)),
    );
  }

  @override
  State<ApplicationClauseLibrary> createState() =>
      ApplicationClauseLibraryState();
}

/// State of [ApplicationClauseLibrary]: the fill in flight and the last
/// refusal.
class ApplicationClauseLibraryState extends State<ApplicationClauseLibrary> {
  /// Whether a fill is in flight.
  bool filling = false;

  /// Why the last tap inserted nothing; null when it did.
  String? refusal;

  /// Fills [clause] and inserts it, or says why not.
  Future<void> tap(ApplicationClauseOption clause) async {
    final facts = ApplicationClauseFacts.bind(clause, widget.facts);
    if (facts.missing.entries.firstOrNull case MapEntry(
      key: final gap,
      value: final type,
    )) {
      setState(
        () => refusal = ApplicationFormStrings.clauseNeedsFact(gap, type),
      );
      return;
    }
    setState(() {
      filling = true;
      refusal = null;
    });
    final result = await widget.fill(clause.id, facts.bound);
    if (!mounted) return;
    setState(() {
      filling = false;
      if (result case ApplicationClauseRefused(:final message)) {
        refusal = message;
      }
    });
    if (result case final ApplicationClauseFilled filled) {
      widget.onInsert(
        filled.only([for (final language in widget.languages) language.code]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final active = widget.enabled && !filling;
    final message = refusal;
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
          for (final clause in widget.clauses)
            _ClauseRow(
              key: ValueKey<String>(clause.id),
              text: ApplicationClausePicker.englishOf(clause),
              enabled: active,
              onTap: () => tap(clause),
            ),
          if (message != null)
            Text(
              message,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
        ],
      ),
    );
  }
}

/// One clause of the library, tapped to insert it.
class _ClauseRow extends StatelessWidget {
  const _ClauseRow({
    required this.text,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: theme.radius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Text(text, style: theme.textTheme.small),
            ),
          ),
        ),
      ),
    );
  }
}
