import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_fill.dart';
import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
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
import 'text_value/application_clause_library.dart';
import 'text_value/application_text_value_field.dart';

/// Pure-UI section editor of an application's declaration, printed above
/// the signatures, written in each print language. Tapping a declaration
/// clause of the library (one per noun: a camp, a championship, a trial)
/// puts its filled text there, to be edited like typed text.
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

  /// The clause library; its declarations are offered.
  final List<ApplicationClauseOption> clauses;

  /// Fills a library clause with the template's facts (the host's call);
  /// with none, the library is not offered. A tapped clause's filled text
  /// becomes the declaration (club_client#336).
  final ApplicationClauseFiller? fillClause;

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
  /// How many clauses were inserted: the key of the text's editor, which
  /// is seeded again from each.
  int inserted = 0;

  /// Makes [filled] the declaration.
  void insert(ApplicationClauseFilled filled) {
    setState(() => inserted++);
    formKey.currentState?.setFieldValue(
      ApplicationFormFields.declarationId,
      ApplicationTextValue.fromJson(filled.text),
    );
  }

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
    final fill = widget.fillClause;
    final library = sources.clausesOf(kind);
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.declarationId: ApplicationTextValue.fromJson(
          widget.initialValues[ApplicationFormFields.declarationId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.declaration,
            field: ApplicationTextValueField(
              id: ApplicationFormFields.declarationId,
              editorKey: ValueKey<int>(inserted),
              modes: const [ApplicationTextMode.custom],
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
          if (fill != null && library.isNotEmpty)
            ApplicationClauseLibrary(
              clauses: library,
              facts: widget.facts,
              languages: widget.languages,
              fill: fill,
              enabled: widget.enabled,
              onInsert: insert,
            ),
        ],
      ),
    );
  }
}
