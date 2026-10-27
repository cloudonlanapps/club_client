import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/application/application_language_option.dart';
import '../../form/form_autofocus.dart';
import '../../form/form_body.dart';
import '../../form/form_contract.dart';
import '../../form/labeled_form_row.dart';
import '../application_form_validators.dart';
import 'application_label_form_fields.dart';

/// Pure-UI form of one of the club's application labels (club_client#396):
/// its text in each of [languages], the club's languages, English first and
/// required. A language left blank is allowed: the server keeps it blank,
/// and Finalize asks for it on a template that prints in it.
///
/// [initialValues] holds [ApplicationLabelFormFields.textId], a map of
/// language code to text. The form owns no title or Save button: the host
/// drives it through a `GlobalKey<ApplicationLabelFormState>`
/// ([FormContract]).
class ApplicationLabelForm extends StatefulWidget {
  const ApplicationLabelForm({
    required this.languages,
    this.initialValues = const {},
    this.enabled = true,
    super.key,
  });

  /// What to start from.
  final Map<String, dynamic> initialValues;

  /// The club's languages, English first.
  final List<ApplicationLanguageOption> languages;

  /// Whether the inputs respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ApplicationLabelForm> createState() => ApplicationLabelFormState();
}

/// State of [ApplicationLabelForm]. Its value is
/// `{textId: {code: text}}`, each text trimmed and a blank one left out.
class ApplicationLabelFormState extends State<ApplicationLabelForm>
    with FormContract<ApplicationLabelForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ApplicationLabelFormFields.textId: <String, String>{
      for (final language in widget.languages)
        if (text(
          values[ApplicationLabelFormFields.textFieldId(language.code)],
        ).isNotEmpty)
          language.code: text(
            values[ApplicationLabelFormFields.textFieldId(language.code)],
          ),
    },
  };

  /// The trimmed text of [raw]; `''` when it holds none.
  static String text(Object? raw) => raw is String ? raw.trim() : '';

  @override
  Widget build(BuildContext context) {
    final seeded = widget.initialValues[ApplicationLabelFormFields.textId];
    return ShadForm(
      key: formKey,
      initialValue: {
        for (final language in widget.languages)
          ApplicationLabelFormFields.textFieldId(
            language.code,
          ): seeded is Map && seeded[language.code] is String
              ? seeded[language.code] as String
              : '',
      },
      child: FormBody(
        error: formError,
        children: [
          for (final (i, language) in widget.languages.indexed)
            LabeledFormRow(
              label: language.name,
              required: language.code == ApplicationLabelFormFields.english,
              field: ShadInputFormField(
                id: ApplicationLabelFormFields.textFieldId(language.code),
                enabled: widget.enabled,
                autofocus: i == 0 && FormAutofocus.allowed,
                keyboardType: TextInputType.text,
                validator: language.code == ApplicationLabelFormFields.english
                    ? ApplicationFormValidators.label
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
