import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_choice_option.dart';
import '../../models/application/application_language_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_section_contract.dart';
import 'facts/application_fact_editor.dart';
import 'facts/application_fact_values.dart';
import 'items/application_items_field.dart';

/// Pure-UI section editor of an application's facts: the values that
/// change each time (dates, times, amounts, names, choices), typed once
/// and named, which the header, clauses and subtitle refer to. Facts are
/// added, removed and moved; each has a name, a type and a value for it.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationFactsFormState>` ([FormContract]).
class ApplicationFactsForm extends StatefulWidget {
  const ApplicationFactsForm({
    required this.initialValues,
    required this.languages,
    this.choices = const [],
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages a name may be given in.
  final List<ApplicationLanguageOption> languages;

  /// The library's choices, for a fact of type `choices`.
  final List<ApplicationChoiceOption> choices;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationFactsForm> createState() => ApplicationFactsFormState();
}

/// State of [ApplicationFactsForm]. Its value is `{factsId: {name: fact}}`,
/// each fact as the template holds it: its `type` and its `value`, or
/// `from` and `to` for a range; a name typed in English alone is one text.
class ApplicationFactsFormState extends State<ApplicationFactsForm>
    with
        FormContract<ApplicationFactsForm>,
        ApplicationSectionContract<ApplicationFactsForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ApplicationFormFields.factsId: ApplicationFactValues.factsOut(
      values[ApplicationFormFields.factsId],
    ),
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.factsId: ApplicationFactValues.rows(
          widget.initialValues[ApplicationFormFields.factsId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.facts,
            field: ApplicationItemsField(
              id: ApplicationFormFields.factsId,
              enabled: widget.enabled,
              noun: ApplicationFormStrings.factNoun,
              addLabel: ApplicationFormStrings.addFact,
              validator: ApplicationFormValidators.facts,
              itemBuilder:
                  ({required initial, required onChanged, required enabled}) =>
                      ApplicationFactEditor(
                        initial: initial,
                        languages: widget.languages,
                        choices: widget.choices,
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
