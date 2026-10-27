import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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
import 'application_languages_field.dart';
import 'application_text_mode.dart';
import 'application_text_sources.dart';
import 'text_value/application_text_value_field.dart';

/// Pure-UI section editor of an application's print languages and the
/// texts at its top and foot: the organisation, the title, the subtitle and
/// the footer line. Each written text has an input per print language; the
/// subtitle may instead be one of the template's [facts]. Picking another
/// print language gives every written text its input at once.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationHeadingFormState>` ([FormContract]).
class ApplicationHeadingForm extends StatefulWidget {
  const ApplicationHeadingForm({
    required this.initialValues,
    required this.languageOptions,
    this.facts = const {},
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The languages of the label catalogue, English among them.
  final List<ApplicationLanguageOption> languageOptions;

  /// The template's facts: the type of each, by name.
  final Map<String, ApplicationFactType> facts;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationHeadingForm> createState() => ApplicationHeadingFormState();
}

/// State of [ApplicationHeadingForm]. Its value is the section as the
/// template's JSON holds it: `languagesId` a list, each text a map of
/// language code to text (the subtitle maybe `{'fact': name}`), and null
/// for an optional text left empty. A text in a language not printed is
/// kept.
class ApplicationHeadingFormState extends State<ApplicationHeadingForm>
    with FormContract<ApplicationHeadingForm> {
  /// The print language beside English now; `''` for none.
  late String other = ApplicationFormValues.otherLanguage(
    widget.initialValues[ApplicationFormFields.languagesId],
  );

  /// The texts of the section, in the order shown.
  static const List<String> textIds = [
    ApplicationFormFields.organisationId,
    ApplicationFormFields.titleId,
    ApplicationFormFields.subtitleId,
    ApplicationFormFields.formFooterId,
  ];

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ApplicationFormFields.languagesId: ApplicationFormValues.languagesOut(
      values[ApplicationFormFields.languagesId],
    ),
    for (final id in textIds)
      id: (values[id] as ApplicationTextValue?)?.toJson(),
  };

  /// Whether anything differs from its initial value. Overridden because
  /// the texts are maps, which an edit replaces: they are compared entry by
  /// entry (rule 8).
  @override
  bool get isDirty {
    final form = formKey.currentState;
    return form != null &&
        !ApplicationFormValues.same(form.initialValue, form.value);
  }

  /// The texts are custom fields, with nothing of their own to focus.
  @override
  bool get focusFirstInvalid => false;

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValues;
    final languages = ApplicationFormValues.printLanguages(
      other,
      widget.languageOptions,
    );
    final sources = ApplicationTextSources(facts: widget.facts);
    ApplicationTextValueField text(
      String id, {
      List<ApplicationTextMode> modes = const [ApplicationTextMode.custom],
      bool required = false,
    }) => ApplicationTextValueField(
      id: id,
      modes: modes,
      languages: languages,
      sources: sources,
      requireEnglish: required,
      enabled: widget.enabled,
      validator: (value) => ApplicationFormValidators.text(
        value,
        sources,
        required: required,
      ),
    );

    return ShadForm(
      key: formKey,
      initialValue: {
        ApplicationFormFields.languagesId: ApplicationFormValues.otherLanguage(
          initial[ApplicationFormFields.languagesId],
        ),
        for (final id in textIds)
          id: ApplicationTextValue.fromJson(initial[id]),
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ApplicationFormStrings.printLanguages,
            field: ApplicationLanguagesField(
              options: widget.languageOptions,
              enabled: widget.enabled,
              onChanged: (code) => setState(() => other = code),
            ),
          ),
          LabeledFormRow(
            label: ApplicationFormStrings.organisation,
            field: text(ApplicationFormFields.organisationId, required: true),
          ),
          LabeledFormRow(
            label: ApplicationFormStrings.title,
            field: text(ApplicationFormFields.titleId, required: true),
          ),
          LabeledFormRow(
            label: ApplicationFormStrings.subtitle,
            field: text(
              ApplicationFormFields.subtitleId,
            ),
          ),
          LabeledFormRow(
            label: ApplicationFormStrings.formFooter,
            field: text(ApplicationFormFields.formFooterId),
          ),
        ],
      ),
    );
  }
}
