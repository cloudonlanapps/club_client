import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_custom_text.dart';
import '../../models/application/application_language_option.dart';
import '../form/form_autofocus.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_form_values.dart';
import 'application_languages_field.dart';

/// Pure-UI form of what a new application draft needs: its title in
/// English and its print languages. The rest is edited section by section
/// once the draft exists.
///
/// [initialValues] is a template's JSON, or a part of it: a copied draft
/// starts from its [ApplicationFormFields.titleId] and
/// [ApplicationFormFields.languagesId]. The form owns no title or Save
/// button: the host drives it through a `GlobalKey<ApplicationCreateFormState>`
/// ([FormContract]).
class ApplicationCreateForm extends StatefulWidget {
  const ApplicationCreateForm({
    required this.languageOptions,
    this.initialValues = const {},
    this.enabled = true,
    this.onSubmitted,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The languages of the label catalogue, English among them.
  final List<ApplicationLanguageOption> languageOptions;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// Called when Enter is pressed in the title; the host points it at its
  /// Save action.
  final VoidCallback? onSubmitted;

  @override
  State<ApplicationCreateForm> createState() => ApplicationCreateFormState();
}

/// State of [ApplicationCreateForm]. Its value is the title under
/// `titleId`, as `{'en': title}` trimmed, and the print languages under
/// `languagesId`, as a list of codes.
class ApplicationCreateFormState extends State<ApplicationCreateForm>
    with FormContract<ApplicationCreateForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ApplicationFormFields.titleId: {
      ApplicationFormFields.english:
          (values[ApplicationFormFields.titleId] as String? ?? '').trim(),
    },
    ApplicationFormFields.languagesId: ApplicationFormValues.languagesOut(
      values[ApplicationFormFields.languagesId],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValues;
    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.titleId:
            ApplicationCustomText.fromJson(
              initial[ApplicationFormFields.titleId],
            ).text[ApplicationFormFields.english] ??
            '',
        ApplicationFormFields.languagesId: ApplicationFormValues.otherLanguage(
          initial[ApplicationFormFields.languagesId],
        ),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.titleInEnglish,
            required: true,
            field: ShadInputFormField(
              id: ApplicationFormFields.titleId,
              enabled: widget.enabled,
              autofocus: FormAutofocus.allowed,
              keyboardType: TextInputType.text,
              validator: ApplicationFormValidators.englishText,
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
          LabeledFormRow(
            label: ApplicationFormStrings.printLanguages,
            field: ApplicationLanguagesField(
              options: widget.languageOptions,
              enabled: widget.enabled,
            ),
          ),
        ],
      ),
    );
  }
}
