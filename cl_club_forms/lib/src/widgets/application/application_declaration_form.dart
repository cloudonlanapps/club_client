import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
import '../../models/application/application_clause_text.dart';
import '../../models/application/application_fact_type.dart';
import '../../models/application/application_language_option.dart';
import '../../models/application/application_text_value.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_section_contract.dart';
import 'application_text_mode.dart';
import 'application_text_sources.dart';
import 'text_value/application_text_value_field.dart';

/// Pure-UI section editor of an application's declaration, printed above
/// the signatures: a declaration clause of the library (one per noun: a
/// camp, a championship, a trial), or written in each print language. A
/// template with none starts at the clause picker.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationDeclarationFormState>` ([FormContract]).
class ApplicationDeclarationForm extends StatefulWidget {
  const ApplicationDeclarationForm({
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

  /// The clause library; its declarations are offered.
  final List<ApplicationClauseOption> clauses;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationDeclarationForm> createState() =>
      ApplicationDeclarationFormState();
}

/// State of [ApplicationDeclarationForm]. Its value is `{declarationId:
/// text}`, the text as the template holds it.
class ApplicationDeclarationFormState extends State<ApplicationDeclarationForm>
    with
        FormContract<ApplicationDeclarationForm>,
        ApplicationSectionContract<ApplicationDeclarationForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ApplicationFormFields.declarationId:
        (values[ApplicationFormFields.declarationId] as ApplicationTextValue?)
            ?.toJson(),
  };

  @override
  Widget build(BuildContext context) {
    final sources = ApplicationTextSources(
      facts: widget.facts,
      clauses: widget.clauses,
    );
    const kind = ApplicationClauseKind.declaration;
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.declarationId:
            ApplicationTextValue.fromJson(
              widget.initialValues[ApplicationFormFields.declarationId],
            ) ??
            const ApplicationClauseText(''),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.declaration,
            field: ApplicationTextValueField(
              id: ApplicationFormFields.declarationId,
              modes: const [
                ApplicationTextMode.clause,
                ApplicationTextMode.custom,
              ],
              languages: widget.languages,
              sources: sources,
              clauseKind: kind,
              requireEnglish: true,
              multiline: true,
              enabled: widget.enabled,
              validator: (value) => ApplicationFormValidators.text(
                value,
                sources,
                required: true,
                kind: kind,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
