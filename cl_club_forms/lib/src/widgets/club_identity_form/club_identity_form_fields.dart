import 'package:cl_club_forms/src/models/form_translated_text.dart';
import 'package:flutter/material.dart';

import 'add_language_row.dart';
import 'club_identity_form.dart';
import 'club_identity_form_section.dart';
import 'club_identity_form_validators.dart';
import 'club_identity_text_input.dart';
import 'translated_text_inputs.dart';

/// The inputs of `ClubIdentityForm`, in four cards: the club, how to reach
/// it, its postal address, and the languages translations are offered in.
class ClubIdentityFormFields extends StatelessWidget {
  const ClubIdentityFormFields({
    required this.initialText,
    required this.initialTranslated,
    required this.languages,
    required this.onAddLanguage,
    this.enabled = true,
    super.key,
  });

  final String Function(String id) initialText;
  final FormTranslatedText Function(String id) initialTranslated;
  final List<String> languages;
  final ValueChanged<String> onAddLanguage;
  final bool enabled;

  Widget text(
    String id,
    String label,
    TextInputType keyboardType, {
    String? Function(String)? validator,
    String? description,
  }) => ClubIdentityTextInput(
    id: id,
    label: label,
    initialValue: initialText(id),
    keyboardType: keyboardType,
    validator: validator,
    description: description,
  );

  Widget translated(
    String id,
    TextInputType keyboardType, {
    bool multiline = false,
  }) => TranslatedTextInputs(
    id: id,
    label: ClubIdentityForm.translatedLabels[id]!,
    initialValue: initialTranslated(id),
    languages: languages,
    keyboardType: keyboardType,
    multiline: multiline,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        ClubIdentityFormSection(
          title: 'Club',
          description:
              'The name the website and the emails the server sends '
              'show. Left empty, the deployment default is used.',
          children: [
            text(ClubIdentityForm.nameId, 'Name', TextInputType.name),
            text(
              ClubIdentityForm.shortNameId,
              'Short name',
              TextInputType.name,
            ),
            translated(ClubIdentityForm.taglineId, TextInputType.text),
            text(
              ClubIdentityForm.inquiryEmailId,
              'Inquiry email',
              TextInputType.emailAddress,
              validator: ClubIdentityFormValidators.email,
              description:
                  'Where messages from the website contact form are sent. '
                  'Not shown publicly.',
            ),
          ],
        ),
        ClubIdentityFormSection(
          title: 'Contact',
          description: 'How the website tells visitors to reach the club.',
          children: [
            text(
              ClubIdentityForm.phoneNumberId,
              'Phone',
              TextInputType.phone,
              validator: ClubIdentityFormValidators.phone,
            ),
            text(
              ClubIdentityForm.whatsappNumberId,
              'WhatsApp number',
              TextInputType.phone,
              validator: ClubIdentityFormValidators.phone,
              description: 'Left empty, WhatsApp links use the phone.',
            ),
            translated(
              ClubIdentityForm.whatsappMessageId,
              TextInputType.text,
              multiline: true,
            ),
            text(
              ClubIdentityForm.emailId,
              'Email',
              TextInputType.emailAddress,
              validator: ClubIdentityFormValidators.email,
            ),
            translated(ClubIdentityForm.emailSubjectId, TextInputType.text),
            text(
              ClubIdentityForm.instagramUrlId,
              'Instagram link',
              TextInputType.url,
              validator: ClubIdentityFormValidators.url,
            ),
          ],
        ),
        ClubIdentityFormSection(
          title: 'Address',
          children: [
            translated(ClubIdentityForm.addressId, TextInputType.streetAddress),
            translated(
              ClubIdentityForm.addressLine2Id,
              TextInputType.streetAddress,
            ),
            translated(ClubIdentityForm.cityId, TextInputType.streetAddress),
            translated(ClubIdentityForm.stateId, TextInputType.streetAddress),
            text(
              ClubIdentityForm.postalCodeId,
              'Postal code',
              TextInputType.number,
            ),
          ],
        ),
        ClubIdentityFormSection(
          title: 'Translations',
          description:
              'Tagline, messages and address take a default text, shown to '
              'everyone, and optionally a text per language. A language '
              'left empty shows the default.',
          children: [
            AddLanguageRow(
              languages: languages,
              onAdd: onAddLanguage,
              enabled: enabled,
            ),
          ],
        ),
      ],
    );
  }
}
