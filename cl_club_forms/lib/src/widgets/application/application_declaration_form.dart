import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_clause_option.dart';
import '../../models/application/application_language_option.dart';
import '../../models/application/application_text_value.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_section_contract.dart';
import 'text_value/application_clause_library.dart';
import 'text_value/application_text_value_field.dart';

/// Pure-UI section editor of an application's declaration, printed above
/// the signatures, written in each print language. Tapping a declaration
/// clause of the library (one per noun: a camp, a championship, a trial)
/// puts its text there as written, `{fact}` gaps included, to be edited
/// like typed text.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationDeclarationFormState>` ([FormContract]).
class ApplicationDeclarationForm extends StatefulWidget {
  const ApplicationDeclarationForm({
    required this.initialValues,
    required this.languages,
    this.clauses = const [],
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// The library texts; its declarations are offered.
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
  /// How many clauses were inserted: the key of the text's editor, which
  /// is seeded again from each.
  int inserted = 0;

  /// Makes [clause]'s text, as written, the declaration.
  void insert(ApplicationClauseOption clause) {
    setState(() => inserted++);
    formKey.currentState?.setFieldValue(
      ApplicationFormFields.declarationId,
      ApplicationTextValue.fromJson(clause.text),
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
    final library = ApplicationClauseLibrary.ofKind(
      widget.clauses,
      ApplicationClauseKind.declaration,
    );
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
              languages: widget.languages,
              requireEnglish: true,
              multiline: true,
              enabled: widget.enabled,
              validator: (value) =>
                  ApplicationFormValidators.text(value, required: true),
            ),
          ),
          if (library.isNotEmpty)
            ApplicationClauseLibrary(
              clauses: library,
              languages: widget.languages,
              enabled: widget.enabled,
              onInsert: insert,
            ),
        ],
      ),
    );
  }
}
