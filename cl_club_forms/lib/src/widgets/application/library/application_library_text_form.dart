import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/application/application_clause_kind.dart';
import '../../../models/application/application_language_option.dart';
import '../../../models/application/application_text_value.dart';
import '../../form/form_autofocus.dart';
import '../../form/form_body.dart';
import '../../form/form_contract.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_strings.dart';
import '../application_form_values.dart';
import '../text_value/application_text_value_field.dart';
import 'application_library_text_form_fields.dart';
import 'application_library_text_form_validators.dart';

/// Pure-UI form of one of the club's library texts (club_client#389): where
/// it is used (its kind), a short name for the editor's lists, and its text
/// in each of [languages], `{fact}` gaps allowed. A term has a heading too.
/// One form creates a text and edits it.
///
/// [initialValues] is keyed by [ApplicationLibraryTextFormFields]: the
/// kind an [ApplicationClauseKind], the name a `String`, the heading and
/// the text maps of language code to text. The form owns no title or
/// Save button: the host drives it through a
/// `GlobalKey<ApplicationLibraryTextFormState>` ([FormContract]).
class ApplicationLibraryTextForm extends StatefulWidget {
  const ApplicationLibraryTextForm({
    required this.languages,
    this.initialValues = const {},
    this.enabled = true,
    super.key,
  });

  /// What to start from; empty for a new text.
  final Map<String, dynamic> initialValues;

  /// The languages a library text may be written in, English first.
  final List<ApplicationLanguageOption> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationLibraryTextForm> createState() =>
      ApplicationLibraryTextFormState();
}

/// State of [ApplicationLibraryTextForm]. Its value is keyed by
/// [ApplicationLibraryTextFormFields]: the kind, the name trimmed, the text
/// as a map of language code to text, and the heading likewise for a term,
/// null for any other kind or when left empty.
class ApplicationLibraryTextFormState extends State<ApplicationLibraryTextForm>
    with FormContract<ApplicationLibraryTextForm> {
  /// The kind picked now; a term shows its heading.
  late ApplicationClauseKind? kind =
      widget.initialValues[ApplicationLibraryTextFormFields.kindId]
          as ApplicationClauseKind?;

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final picked =
        values[ApplicationLibraryTextFormFields.kindId]
            as ApplicationClauseKind;
    final heading =
        values[ApplicationLibraryTextFormFields.headingId]
            as ApplicationTextValue?;
    return {
      ApplicationLibraryTextFormFields.kindId: picked,
      ApplicationLibraryTextFormFields.nameId:
          (values[ApplicationLibraryTextFormFields.nameId] as String? ?? '')
              .trim(),
      ApplicationLibraryTextFormFields.headingId:
          picked == ApplicationClauseKind.rule ? heading?.toJson() : null,
      ApplicationLibraryTextFormFields.textId:
          (values[ApplicationLibraryTextFormFields.textId]
                  as ApplicationTextValue)
              .toJson(),
    };
  }

  /// Whether anything differs from its initial value. Overridden because
  /// the texts are maps, which an edit replaces: they are compared entry by
  /// entry (rule 8).
  @override
  bool get isDirty {
    final form = formKey.currentState;
    return form != null &&
        !ApplicationFormValues.same(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValues;
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationLibraryTextFormFields.kindId:
            initial[ApplicationLibraryTextFormFields.kindId],
        ApplicationLibraryTextFormFields.nameId:
            initial[ApplicationLibraryTextFormFields.nameId] as String? ?? '',
        ApplicationLibraryTextFormFields.headingId:
            ApplicationTextValue.fromJson(
              initial[ApplicationLibraryTextFormFields.headingId],
            ),
        ApplicationLibraryTextFormFields.textId: ApplicationTextValue.fromJson(
          initial[ApplicationLibraryTextFormFields.textId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.libraryKind,
            required: true,
            field: ShadSelectFormField<ApplicationClauseKind>(
              id: ApplicationLibraryTextFormFields.kindId,
              initialValue: kind,
              enabled: widget.enabled,
              placeholder: const Text(
                ApplicationFormStrings.libraryKindPlaceholder,
              ),
              validator: ApplicationLibraryTextFormValidators.kind,
              options: [
                for (final option in ApplicationClauseKind.values)
                  ShadOption(
                    value: option,
                    child: Text(ApplicationFormStrings.kindName(option)),
                  ),
              ],
              selectedOptionBuilder: (context, value) =>
                  Text(ApplicationFormStrings.kindName(value)),
              onChanged: (value) => setState(() => kind = value),
            ),
          ),
          LabeledFormRow(
            label: ApplicationFormStrings.libraryName,
            required: true,
            field: ShadInputFormField(
              id: ApplicationLibraryTextFormFields.nameId,
              enabled: widget.enabled,
              autofocus: FormAutofocus.allowed,
              keyboardType: TextInputType.text,
              maxLength: ApplicationLibraryTextFormFields.nameMaxLength,
              validator: ApplicationLibraryTextFormValidators.name,
            ),
          ),
          if (kind == ApplicationClauseKind.rule)
            LabeledFormRow(
              label: ApplicationFormStrings.libraryHeading,
              field: ApplicationTextValueField(
                id: ApplicationLibraryTextFormFields.headingId,
                languages: widget.languages,
                enabled: widget.enabled,
              ),
            ),
          LabeledFormRow(
            label: ApplicationFormStrings.libraryText,
            required: true,
            field: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ApplicationFormStrings.libraryTextHint,
                  style: theme.textTheme.muted,
                ),
                ApplicationTextValueField(
                  id: ApplicationLibraryTextFormFields.textId,
                  languages: widget.languages,
                  multiline: true,
                  enabled: widget.enabled,
                  validator: ApplicationLibraryTextFormValidators.text,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
