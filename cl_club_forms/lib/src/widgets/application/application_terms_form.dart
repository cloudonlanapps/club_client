import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_option.dart';
import '../../models/application/application_custom_text.dart';
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
import 'sections/application_term_editor.dart';

/// Pure-UI section editor of an application's terms, printed from page 2:
/// each a rule clause of the library with its gaps bound to the template's
/// facts, or a heading and a text written in each print language. Terms
/// are added, removed and moved.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationTermsFormState>` ([FormContract]).
class ApplicationTermsForm extends StatefulWidget {
  const ApplicationTermsForm({
    required this.initialValues,
    required this.languages,
    this.facts = const {},
    this.clauses = const [],
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The template's facts: the type of each, by name.
  final Map<String, ApplicationFactType> facts;

  /// The clause library; its rules are offered.
  final List<ApplicationClauseOption> clauses;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationTermsForm> createState() => ApplicationTermsFormState();
}

/// State of [ApplicationTermsForm]. Its value is the list of terms under
/// `termsId`, each as the template holds it: a clause reference, or a
/// `heading` and a `body`.
class ApplicationTermsFormState extends State<ApplicationTermsForm>
    with
        FormContract<ApplicationTermsForm>,
        ApplicationSectionContract<ApplicationTermsForm> {
  @override
  Widget build(BuildContext context) {
    final sources = ApplicationTextSources(
      facts: widget.facts,
      clauses: widget.clauses,
    );
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.termsId: ApplicationFormValues.list(
          widget.initialValues[ApplicationFormFields.termsId],
          ApplicationFormValues.term,
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.terms,
            field: ApplicationItemsField(
              id: ApplicationFormFields.termsId,
              enabled: widget.enabled,
              noun: ApplicationFormStrings.termNoun,
              addLabel: ApplicationFormStrings.addTerm,
              newItem: () => ApplicationCustomText.none.toJson(),
              validator: (items) => ApplicationFormValidators.items(
                items,
                ApplicationFormStrings.termNoun,
                (item) => ApplicationFormValidators.term(item, sources),
              ),
              itemBuilder:
                  ({required initial, required onChanged, required enabled}) =>
                      ApplicationTermEditor(
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
