import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
import '../../models/application/application_custom_text.dart';
import '../../models/application/application_fact_type.dart';
import '../../models/application/application_language_option.dart';
import '../../models/application/application_text_value.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_form_values.dart';
import 'application_section_contract.dart';
import 'application_text_mode.dart';
import 'application_text_sources.dart';
import 'items/application_items_field.dart';
import 'text_value/application_text_value_editor.dart';

/// Pure-UI section editor of an application's additional selections: the
/// lines printed with an empty checkbox the member ticks by hand, each a
/// selection clause of the library with its gaps bound to the template's
/// facts, or written in each print language. Selections are added,
/// removed and moved.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationSelectionsFormState>` ([FormContract]).
class ApplicationSelectionsForm extends StatefulWidget {
  const ApplicationSelectionsForm({
    required this.initialValues,
    required this.languages,
    this.facts = const {},
    this.clauses = const [],
    this.enabled = true,
    super.key,
  });

  /// The modes a selection may take; a new one takes the first.
  // A printed text is a language map only (club_sdk#76): a clause or fact
  // reference is refused by the server. Inserting a library clause's filled
  // text is club_client#336.
  static const List<ApplicationTextMode> modes = [ApplicationTextMode.custom];

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The template's facts: the type of each, by name.
  final Map<String, ApplicationFactType> facts;

  /// The clause library; its selection clauses are offered.
  final List<ApplicationClauseOption> clauses;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationSelectionsForm> createState() =>
      ApplicationSelectionsFormState();
}

/// State of [ApplicationSelectionsForm]. Its value is the list of
/// selections under `selectionsId`, each as the template holds it.
class ApplicationSelectionsFormState extends State<ApplicationSelectionsForm>
    with
        FormContract<ApplicationSelectionsForm>,
        ApplicationSectionContract<ApplicationSelectionsForm> {
  @override
  Widget build(BuildContext context) {
    final sources = ApplicationTextSources(
      facts: widget.facts,
      clauses: widget.clauses,
    );
    const kind = ApplicationClauseKind.selection;
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.selectionsId: ApplicationFormValues.list(
          widget.initialValues[ApplicationFormFields.selectionsId],
          ApplicationFormValues.text,
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.selections,
            field: ApplicationItemsField(
              id: ApplicationFormFields.selectionsId,
              enabled: widget.enabled,
              noun: ApplicationFormStrings.selectionNoun,
              addLabel: ApplicationFormStrings.addSelection,
              newItem: () => ApplicationCustomText.none.toJson(),
              validator: (items) => ApplicationFormValidators.items(
                items,
                ApplicationFormStrings.selectionNoun,
                (item) => ApplicationFormValidators.text(
                  item,
                  sources,
                  required: true,
                  kind: kind,
                ),
              ),
              itemBuilder:
                  ({required initial, required onChanged, required enabled}) =>
                      ApplicationTextValueEditor(
                        modes: ApplicationSelectionsForm.modes,
                        languages: widget.languages,
                        sources: sources,
                        clauseKind: kind,
                        requireEnglish: true,
                        initialValue: ApplicationTextValue.fromJson(initial),
                        enabled: enabled,
                        onChanged: (value) => onChanged(value?.toJson()),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
