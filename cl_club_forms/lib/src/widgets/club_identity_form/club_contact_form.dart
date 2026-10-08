import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'club_contact_form_fields.dart';
import 'club_identity_form_validators.dart';
import 'club_identity_form_values.dart';
import 'club_identity_text_input.dart';
import 'translated_text_inputs.dart';

/// Pure-UI section form for how to reach the club: phone, WhatsApp, email and
/// Instagram (no SDK / no Riverpod).
///
/// Plain fields are `String`s; translatable fields are `FormTranslatedText`s,
/// a default plus one text per language of [languages]. Each input is its
/// own form field; `validate()` gathers them back into one value per field
/// id of [ClubContactFormFields], every text trimmed and empty translations
/// dropped. A translation without its default text is refused with a
/// form-level message.
///
/// Fields only: the host supplies the card and the buttons, and drives the
/// form through a `GlobalKey<ClubContactFormState>` ([FormContract]).
class ClubContactForm extends StatefulWidget {
  const ClubContactForm({
    required this.initialValues,
    this.languages = const [],
    this.enabled = true,
    super.key,
  });

  /// Keyed by the ids of [ClubContactFormFields]: a `String` for each plain
  /// text field, a `FormTranslatedText` for each translatable one; missing
  /// reads empty. Other keys are ignored.
  final Map<String, dynamic> initialValues;

  /// The language codes each translatable field offers a translation in.
  final List<String> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ClubContactForm> createState() => ClubContactFormState();
}

/// State of [ClubContactForm]. Its values are keyed by the ids of
/// [ClubContactFormFields].
class ClubContactFormState extends State<ClubContactForm>
    with FormContract<ClubContactForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      ClubIdentityFormValues.gather(
        raw: values,
        initialValues: widget.initialValues,
        textIds: ClubContactFormFields.textIds,
        translatedIds: ClubContactFormFields.translatedIds,
        languages: widget.languages,
      );

  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      ClubIdentityFormValues.missingDefaultError(
        gathered: assemble(values),
        translatedIds: ClubContactFormFields.translatedIds,
        labels: ClubContactFormFields.labels,
      );

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      initialValue: ClubIdentityFormValues.spread(
        values: widget.initialValues,
        textIds: ClubContactFormFields.textIds,
        translatedIds: ClubContactFormFields.translatedIds,
        languages: widget.languages,
      ),
      onChanged: () => setFormError(null),
      child: FormBody(
        error: formError,
        children: [
          ClubIdentityTextInput(
            id: ClubContactFormFields.phoneNumberId,
            label: ClubContactFormFields.phoneNumberLabel,
            keyboardType: TextInputType.phone,
            enabled: widget.enabled,
            validator: ClubIdentityFormValidators.phone,
          ),
          ClubIdentityTextInput(
            id: ClubContactFormFields.whatsappNumberId,
            label: ClubContactFormFields.whatsappNumberLabel,
            keyboardType: TextInputType.phone,
            enabled: widget.enabled,
            validator: ClubIdentityFormValidators.phone,
            description: ClubContactFormFields.whatsappNumberHelp,
          ),
          TranslatedTextInputs(
            id: ClubContactFormFields.whatsappMessageId,
            label: ClubContactFormFields.whatsappMessageLabel,
            languages: widget.languages,
            enabled: widget.enabled,
            multiline: true,
          ),
          ClubIdentityTextInput(
            id: ClubContactFormFields.emailId,
            label: ClubContactFormFields.emailLabel,
            keyboardType: TextInputType.emailAddress,
            enabled: widget.enabled,
            validator: ClubIdentityFormValidators.email,
          ),
          TranslatedTextInputs(
            id: ClubContactFormFields.emailSubjectId,
            label: ClubContactFormFields.emailSubjectLabel,
            languages: widget.languages,
            enabled: widget.enabled,
          ),
          ClubIdentityTextInput(
            id: ClubContactFormFields.instagramUrlId,
            label: ClubContactFormFields.instagramUrlLabel,
            keyboardType: TextInputType.url,
            enabled: widget.enabled,
            validator: ClubIdentityFormValidators.url,
          ),
        ],
      ),
    );
  }
}
