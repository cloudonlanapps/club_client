import 'package:flutter/material.dart';

import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import 'application_custom_text_inputs.dart';

/// Edits one printed text of an application: its text per print language.
///
/// It reports the text through [onChanged] on every edit: trimmed, empty
/// languages left out, and null when no language has any. A language not
/// shown keeps what it was seeded with. It is seeded once from
/// [initialValue].
class ApplicationTextValueEditor extends StatefulWidget {
  const ApplicationTextValueEditor({
    required this.languages,
    required this.onChanged,
    this.initialValue,
    this.requireEnglish = false,
    this.multiline = false,
    this.label,
    this.enabled = true,
    super.key,
  });

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The text to start from.
  final ApplicationTextValue? initialValue;

  /// Called with the text after every edit.
  final ValueChanged<ApplicationTextValue?> onChanged;

  /// Whether the English input is marked required.
  final bool requireEnglish;

  /// Several lines per input.
  final bool multiline;

  /// What the text is, put before each language's name.
  final String? label;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<ApplicationTextValueEditor> createState() =>
      ApplicationTextValueEditorState();
}

/// State of [ApplicationTextValueEditor]: the text of each language.
class ApplicationTextValueEditorState
    extends State<ApplicationTextValueEditor> {
  /// The text as seeded, for the languages not shown.
  Map<String, String> customSeed = const {};

  /// The text of each language shown, by code.
  final Map<String, TextEditingController> custom = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialValue case ApplicationCustomText(:final text)) {
      customSeed = text;
    }
  }

  @override
  void dispose() {
    for (final controller in custom.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The controller of [code]'s text, made when first shown.
  TextEditingController controllerOf(String code) => custom.putIfAbsent(
    code,
    () => TextEditingController(text: customSeed[code] ?? ''),
  );

  /// The text as it is now.
  ApplicationTextValue? get current => ApplicationTextValue.fromJson({
    ...customSeed,
    for (final entry in custom.entries) entry.key: entry.value.text,
  });

  /// Reports the text.
  void report() => widget.onChanged(current);

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return ApplicationCustomTextInputs(
      languages: w.languages,
      controllers: {
        for (final language in w.languages)
          language.code: controllerOf(language.code),
      },
      enabled: w.enabled,
      requireEnglish: w.requireEnglish,
      multiline: w.multiline,
      label: w.label,
      onChanged: report,
    );
  }
}
