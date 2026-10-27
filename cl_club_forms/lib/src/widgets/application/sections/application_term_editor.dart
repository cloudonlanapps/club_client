import 'package:flutter/material.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import '../text_value/application_text_value_editor.dart';

/// Edits one term of an application: a heading and a text written in each
/// print language.
///
/// It reports the term as the template's JSON holds it through [onChanged]
/// on every edit; it is seeded once from [initial].
class ApplicationTermEditor extends StatefulWidget {
  const ApplicationTermEditor({
    required this.initial,
    required this.languages,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The term to start from, as the template's JSON holds it.
  final Object? initial;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// Called with the term after every edit.
  final ValueChanged<Object?> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationTermEditor> createState() => ApplicationTermEditorState();
}

/// State of [ApplicationTermEditor]: the heading and the text.
class ApplicationTermEditorState extends State<ApplicationTermEditor> {
  /// The heading.
  ApplicationTextValue? heading;

  /// The text.
  ApplicationTextValue? body;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final term = initial is Map ? initial : const <Object?, Object?>{};
    heading = ApplicationTextValue.fromJson(
      term[ApplicationFormFields.headingKey],
    );
    body = ApplicationTextValue.fromJson(term[ApplicationFormFields.bodyKey]);
  }

  /// The term as the template's JSON holds it.
  Object? get current => {
    if (heading != null) ApplicationFormFields.headingKey: heading!.toJson(),
    if (body != null) ApplicationFormFields.bodyKey: body!.toJson(),
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
      languages: widget.languages,
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
    );
  }
}
