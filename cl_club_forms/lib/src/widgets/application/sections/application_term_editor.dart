import 'package:flutter/material.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import '../application_text_mode.dart';
import '../application_text_sources.dart';
import '../text_value/application_text_mode_select.dart';
import '../text_value/application_text_value_editor.dart';

/// Edits one term of an application: a rule clause of the library with its
/// gaps bound to facts, or a heading and a text written in each print
/// language. What was given one way is kept while the other is tried.
///
/// It reports the term as the template's JSON holds it through [onChanged]
/// on every edit; it is seeded once from [initial].
class ApplicationTermEditor extends StatefulWidget {
  const ApplicationTermEditor({
    required this.initial,
    required this.languages,
    required this.sources,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The ways a term may be given; a new one takes the first.
  static const List<ApplicationTextMode> modes = [
    ApplicationTextMode.clause,
    ApplicationTextMode.custom,
  ];

  /// The term to start from, as the template's JSON holds it.
  final Object? initial;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The facts and clauses a term may name.
  final ApplicationTextSources sources;

  /// Called with the term after every edit.
  final ValueChanged<Object?> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationTermEditor> createState() => ApplicationTermEditorState();
}

/// State of [ApplicationTermEditor]: the way the term is given, and what
/// each way holds.
class ApplicationTermEditorState extends State<ApplicationTermEditor> {
  /// The way the term is given now.
  ApplicationTextMode mode = ApplicationTextMode.clause;

  /// The rule clause.
  ApplicationTextValue? clause;

  /// The heading written here.
  ApplicationTextValue? heading;

  /// The text written here.
  ApplicationTextValue? body;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final term = initial is Map ? initial : const <Object?, Object?>{};
    if (term.containsKey(ApplicationTextValue.clauseKey)) {
      clause = ApplicationTextValue.fromJson(term);
    } else {
      mode = ApplicationTextMode.custom;
      heading = ApplicationTextValue.fromJson(
        term[ApplicationFormFields.headingKey],
      );
      body = ApplicationTextValue.fromJson(term[ApplicationFormFields.bodyKey]);
    }
  }

  /// The term as the template's JSON holds it.
  Object? get current => switch (mode) {
    ApplicationTextMode.custom => {
      if (heading != null) ApplicationFormFields.headingKey: heading!.toJson(),
      if (body != null) ApplicationFormFields.bodyKey: body!.toJson(),
    },
    _ => clause?.toJson(),
  };

  /// Takes up [changed], then reports.
  void update(VoidCallback changed) {
    setState(changed);
    widget.onChanged(current);
  }

  @override
  Widget build(BuildContext context) {
    ApplicationTextValueEditor custom(
      String label,
      ApplicationTextValue? value,
      ValueChanged<ApplicationTextValue?> set, {
      bool multiline = false,
    }) => ApplicationTextValueEditor(
      key: ValueKey<String>(label),
      modes: const [ApplicationTextMode.custom],
      languages: widget.languages,
      sources: widget.sources,
      label: label,
      requireEnglish: true,
      multiline: multiline,
      initialValue: value,
      enabled: widget.enabled,
      onChanged: (changed) => update(() => set(changed)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        ApplicationTextModeSelect(
          modes: ApplicationTermEditor.modes,
          value: mode,
          enabled: widget.enabled,
          onChanged: (picked) => update(() => mode = picked),
        ),
        if (mode == ApplicationTextMode.clause)
          ApplicationTextValueEditor(
            modes: const [ApplicationTextMode.clause],
            languages: widget.languages,
            sources: widget.sources,
            clauseKind: ApplicationClauseKind.rule,
            initialValue: clause,
            enabled: widget.enabled,
            onChanged: (value) => update(() => clause = value),
          )
        else ...[
          custom(
            ApplicationFormStrings.heading,
            heading,
            (value) => heading = value,
          ),
          custom(
            ApplicationFormStrings.text,
            body,
            (value) => body = value,
            multiline: true,
          ),
        ],
      ],
    );
  }
}
