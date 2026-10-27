import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_fill.dart';
import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
import '../../models/application/application_fact_type.dart';
import '../../models/application/application_language_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_form_values.dart';
import 'application_section_contract.dart';
import 'application_text_sources.dart';
import 'items/application_items_field.dart';
import 'sections/application_note_editor.dart';
import 'text_value/application_clause_library.dart';

/// Pure-UI section editor of the notes boxed under an application's terms
/// (a reminder, a motto): each a note clause of the library or written in
/// each print language, with an optional attribution written here. Notes
/// are added, removed and moved.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationNotesFormState>` ([FormContract]).
class ApplicationNotesForm extends StatefulWidget {
  const ApplicationNotesForm({
    required this.initialValues,
    required this.languages,
    this.facts = const {},
    this.clauses = const [],
    this.fillClause,
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The template's facts: the type of each, by name.
  final Map<String, ApplicationFactType> facts;

  /// The clause library; its notes are offered.
  final List<ApplicationClauseOption> clauses;

  /// Fills a library clause with the template's facts (the host's call);
  /// with none, the library is not offered. A tapped clause is added as a
  /// new item holding its filled text (club_client#336).
  final ApplicationClauseFiller? fillClause;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationNotesForm> createState() => ApplicationNotesFormState();
}

/// State of [ApplicationNotesForm]. Its value is the list of notes under
/// `termsNotesId`, each a `text` and maybe an `attribution`, as the
/// template holds them; a note seeded as a bare text comes back under
/// `text`.
class ApplicationNotesFormState extends State<ApplicationNotesForm>
    with
        FormContract<ApplicationNotesForm>,
        ApplicationSectionContract<ApplicationNotesForm> {
  @override
  Widget build(BuildContext context) {
    final sources = ApplicationTextSources(
      facts: widget.facts,
      clauses: widget.clauses,
    );
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.termsNotesId: ApplicationFormValues.list(
          widget.initialValues[ApplicationFormFields.termsNotesId],
          ApplicationNoteEditor.noteOf,
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.notes,
            field: ApplicationItemsField(
              id: ApplicationFormFields.termsNotesId,
              enabled: widget.enabled,
              noun: ApplicationFormStrings.noteNoun,
              addLabel: ApplicationFormStrings.addNote,
              insertBuilder: ApplicationClauseLibrary.forItems(
                clauses: sources.clausesOf(ApplicationClauseKind.note),
                facts: widget.facts,
                languages: widget.languages,
                fill: widget.fillClause,
                enabled: widget.enabled,
                item: (filled) => {ApplicationFormFields.textKey: filled.text},
              ),
              newItem: () => ApplicationNoteEditor.noteOf(null),
              validator: (items) => ApplicationFormValidators.items(
                items,
                ApplicationFormStrings.noteNoun,
                (item) => ApplicationFormValidators.note(item, sources),
              ),
              itemBuilder:
                  ({required initial, required onChanged, required enabled}) =>
                      ApplicationNoteEditor(
                        initial: initial,
                        languages: widget.languages,
                        sources: sources,
                        enabled: enabled,
                        onChanged: onChanged,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
