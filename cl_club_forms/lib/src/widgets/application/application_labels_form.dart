import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/application/application_label_option.dart';
import '../../models/application/application_language_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'application_form_fields.dart';
import 'application_form_strings.dart';
import 'application_form_validators.dart';
import 'application_label_values.dart';

/// Pure-UI section editor of an application's standard labels (section
/// headings, field labels, the photo box …): every label of the catalogue
/// with an input per print language, pre-filled from the template's
/// override or else the catalogue. What differs from the catalogue is
/// returned as an override.
///
/// [initialValues] is the template's JSON, or the part of it this section
/// holds. The form owns no title or Save button: the host drives it
/// through a `GlobalKey<ApplicationLabelsFormState>` ([FormContract]).
class ApplicationLabelsForm extends StatefulWidget {
  const ApplicationLabelsForm({
    required this.initialValues,
    required this.labels,
    required this.languages,
    this.enabled = true,
    super.key,
  });

  /// What to start from, as the template's JSON holds it.
  final Map<String, dynamic> initialValues;

  /// The label catalogue, in the order shown.
  final List<ApplicationLabelOption> labels;

  /// The print languages, in order.
  final List<ApplicationLanguageOption> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationLabelsForm> createState() => ApplicationLabelsFormState();
}

/// State of [ApplicationLabelsForm]. Its value is `labelOverridesId`'s map
/// of label id to its text by language, for each label that differs from
/// the catalogue, with every language of the label.
class ApplicationLabelsFormState extends State<ApplicationLabelsForm>
    with FormContract<ApplicationLabelsForm> {
  /// The template's overrides as seeded.
  Map<String, Map<String, String>> get seeded =>
      ApplicationLabelValues.overrides(
        widget.initialValues[ApplicationFormFields.labelOverridesId],
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ApplicationFormFields.labelOverridesId: ApplicationLabelValues.overridesOut(
      values,
      widget.labels,
      widget.languages,
      seeded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      // Label ids hold `.`, which would otherwise read as nesting.
      fieldIdSeparator: null,
      initialValue: ApplicationLabelValues.inputs(
        widget.labels,
        widget.languages,
        seeded,
      ),
      child: FormBody(
        error: formError,
        children: [
          for (final label in widget.labels)
            for (final language in widget.languages)
              LabeledFormRow(
                label: ApplicationFormStrings.labelIn(
                  label.text[ApplicationFormFields.english] ?? label.id,
                  language.name,
                ),
                required: true,
                field: ShadInputFormField(
                  id: ApplicationFormFields.labelFieldId(
                    label.id,
                    language.code,
                  ),
                  enabled: widget.enabled,
                  keyboardType: TextInputType.text,
                  validator: ApplicationFormValidators.label,
                ),
              ),
        ],
      ),
    );
  }
}
