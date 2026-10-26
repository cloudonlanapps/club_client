import 'package:flutter/material.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_clause_text.dart';
import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_fact_text.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../application_text_mode.dart';
import '../application_text_sources.dart';
import 'application_text_mode_select.dart';
import 'application_text_value_inputs.dart';

/// Edits one printed text of an application: where it comes from, among
/// [modes], and then its text per print language, its fact, or its clause
/// with a fact for each gap.
///
/// It reports the text through [onChanged] on every edit: custom text
/// trimmed, empty languages left out, and null when no language has any.
/// What was typed for one mode is kept while another is tried. It is
/// seeded once from [initialValue].
class ApplicationTextValueEditor extends StatefulWidget {
  const ApplicationTextValueEditor({
    required this.modes,
    required this.languages,
    required this.sources,
    required this.onChanged,
    this.initialValue,
    this.clauseKind,
    this.requireEnglish = false,
    this.multiline = false,
    this.label,
    this.enabled = true,
    super.key,
  }) : assert(modes.length > 0, 'A text needs a mode');

  /// The modes offered; a new text takes the first.
  final List<ApplicationTextMode> modes;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The facts and clauses a reference may name.
  final ApplicationTextSources sources;

  /// The clauses offered are those of this kind; all when null.
  final ApplicationClauseKind? clauseKind;

  /// The text to start from.
  final ApplicationTextValue? initialValue;

  /// Called with the text after every edit.
  final ValueChanged<ApplicationTextValue?> onChanged;

  /// Whether custom text marks its English input required.
  final bool requireEnglish;

  /// Several lines per custom input.
  final bool multiline;

  /// What the text is, put before each language's name.
  final String? label;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationTextValueEditor> createState() =>
      ApplicationTextValueEditorState();
}

/// State of [ApplicationTextValueEditor]: the mode, and what each mode
/// holds.
class ApplicationTextValueEditorState
    extends State<ApplicationTextValueEditor> {
  /// Where the text comes from now.
  late ApplicationTextMode mode;

  /// The custom text as seeded, for the languages not shown.
  Map<String, String> customSeed = const {};

  /// The custom text of each language shown, by code.
  final Map<String, TextEditingController> custom = {};

  /// The chosen fact; `''` for none.
  String fact = '';

  /// The chosen clause; `''` for none.
  String clause = '';

  /// The fact of each gap of the clause, by gap name.
  Map<String, String> args = {};

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue;
    final seeded = ApplicationTextMode.of(value);
    mode = seeded != null && widget.modes.contains(seeded)
        ? seeded
        : widget.modes.first;
    switch (value) {
      case ApplicationCustomText(:final text):
        customSeed = text;
      case ApplicationFactText(fact: final name):
        fact = name;
      case ApplicationClauseText(clause: final id, args: final bound):
        clause = id;
        args = Map.of(bound);
    }
  }

  @override
  void dispose() {
    for (final controller in custom.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The controller of [code]'s custom text, made when first shown.
  TextEditingController controllerOf(String code) => custom.putIfAbsent(
    code,
    () => TextEditingController(text: customSeed[code] ?? ''),
  );

  /// The text as it is now.
  ApplicationTextValue? get current => switch (mode) {
    ApplicationTextMode.fact => ApplicationFactText(fact),
    ApplicationTextMode.clause => ApplicationClauseText(clause, Map.of(args)),
    ApplicationTextMode.custom => ApplicationTextValue.fromJson({
      ...customSeed,
      for (final entry in custom.entries) entry.key: entry.value.text,
    }),
  };

  /// Reports the text.
  void report() => widget.onChanged(current);

  /// Takes up [changed], then reports.
  void update(VoidCallback changed) {
    setState(changed);
    report();
  }

  /// Picks [id], keeping the facts of the gaps it shares with the clause
  /// before.
  void pickClause(String id) => update(() {
    clause = id;
    final gaps = widget.sources.clauses[id]?.gaps ?? const {};
    args = {
      for (final entry in args.entries)
        if (gaps.containsKey(entry.key)) entry.key: entry.value,
    };
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.rowGap,
      children: [
        if (widget.modes.length > 1)
          ApplicationTextModeSelect(
            modes: widget.modes,
            value: mode,
            enabled: widget.enabled,
            onChanged: (picked) => update(() => mode = picked),
          ),
        ApplicationTextValueInputs(editor: this),
      ],
    );
  }
}
