import 'package:flutter/material.dart';

import '../../../constants/form_spacing.dart';
import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_custom_text.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../application_completeness.dart';
import '../application_form_fields.dart';
import '../application_form_strings.dart';
import '../application_text_mode.dart';
import '../application_text_sources.dart';
import '../text_value/application_text_value_editor.dart';

/// Edits one note under the terms of an application: its text, a note
/// clause of the library or written in each print language, and an
/// optional attribution written here.
///
/// It reports the note as the template's JSON holds it, its text under
/// `text` even when seeded from a bare text, through [onChanged] on every
/// edit; it is seeded once from [initial].
class ApplicationNoteEditor extends StatefulWidget {
  const ApplicationNoteEditor({
    required this.initial,
    required this.languages,
    required this.sources,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The ways a note's text may be given; a new one takes the first.
  // A printed text is a language map only (club_sdk#76): a clause or fact
  // reference is refused by the server. Inserting a library clause's filled
  // text is club_client#336.
  static const List<ApplicationTextMode> modes = [ApplicationTextMode.custom];

  /// The note to start from, as the template's JSON holds it.
  final Object? initial;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The facts and clauses a note may name.
  final ApplicationTextSources sources;

  /// Called with the note after every edit.
  final ValueChanged<Object?> onChanged;

  /// Whether the editor takes input.
  final bool enabled;

  /// [json], a note as the template holds it, with its text under `text`.
  static Map<String, Object?> noteOf(Object? json) {
    final text = ApplicationTextValue.fromJson(
      ApplicationCompleteness.noteText(json),
    );
    final attribution = json is Map
        ? ApplicationTextValue.fromJson(
            json[ApplicationFormFields.attributionKey],
          )
        : null;
    return {
      ApplicationFormFields.textKey: (text ?? ApplicationCustomText.none)
          .toJson(),
      if (attribution != null)
        ApplicationFormFields.attributionKey: attribution.toJson(),
    };
  }

  @override
  State<ApplicationNoteEditor> createState() => ApplicationNoteEditorState();
}

/// State of [ApplicationNoteEditor]: the note's text and attribution.
class ApplicationNoteEditorState extends State<ApplicationNoteEditor> {
  /// The note's text.
  ApplicationTextValue? text;

  /// The note's attribution.
  ApplicationTextValue? attribution;

  @override
  void initState() {
    super.initState();
    final note = ApplicationNoteEditor.noteOf(widget.initial);
    text = ApplicationTextValue.fromJson(note[ApplicationFormFields.textKey]);
    attribution = ApplicationTextValue.fromJson(
      note[ApplicationFormFields.attributionKey],
    );
  }

  /// Takes up [changed], then reports.
  void update(VoidCallback changed) {
    changed();
    widget.onChanged({
      ApplicationFormFields.textKey: text?.toJson(),
      if (attribution != null)
        ApplicationFormFields.attributionKey: attribution!.toJson(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        ApplicationTextValueEditor(
          modes: ApplicationNoteEditor.modes,
          languages: widget.languages,
          sources: widget.sources,
          clauseKind: ApplicationClauseKind.note,
          requireEnglish: true,
          multiline: true,
          initialValue: text,
          enabled: widget.enabled,
          onChanged: (value) => update(() => text = value),
        ),
        ApplicationTextValueEditor(
          modes: const [ApplicationTextMode.custom],
          languages: widget.languages,
          sources: widget.sources,
          label: ApplicationFormStrings.attribution,
          initialValue: attribution,
          enabled: widget.enabled,
          onChanged: (value) => update(() => attribution = value),
        ),
      ],
    );
  }
}
