import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'club_details_form_fields.dart';
import 'club_identity_form_validators.dart';
import 'club_identity_form_values.dart';
import 'club_identity_text_input.dart';
import 'translated_text_inputs.dart';

/// Pure-UI section form for the club itself: its name, short name, tagline
/// and the address its website inquiries go to (no SDK / no Riverpod).
///
/// Plain fields are `String`s; translatable fields are `FormTranslatedText`s,
/// a default plus one text per language of [languages]. Each input is its
/// own form field; `validate()` gathers them back into one value per field
/// id of [ClubDetailsFormFields], every text trimmed and empty translations
/// dropped. A translation without its default text is refused with a
/// form-level message.
///
/// Fields only: the host supplies the card and the buttons, and drives the
/// form through a `GlobalKey<ClubDetailsFormState>` ([FormContract]).
class ClubDetailsForm extends StatefulWidget {
  const ClubDetailsForm({
    required this.initialValues,
    this.languages = const [],
    this.enabled = true,
    super.key,
  });

  /// Keyed by the ids of [ClubDetailsFormFields]: a `String` for each plain
  /// text field, a `FormTranslatedText` for each translatable one; missing
  /// reads empty. Other keys are ignored.
  final Map<String, dynamic> initialValues;

  /// The language codes each translatable field offers a translation in.
  final List<String> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ClubDetailsForm> createState() => ClubDetailsFormState();
}

/// State of [ClubDetailsForm]. Its values are keyed by the ids of
/// [ClubDetailsFormFields].
class ClubDetailsFormState extends State<ClubDetailsForm>
    with FormContract<ClubDetailsForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      ClubIdentityFormValues.gather(
        raw: values,
        initialValues: widget.initialValues,
        textIds: ClubDetailsFormFields.textIds,
        translatedIds: ClubDetailsFormFields.translatedIds,
        languages: widget.languages,
      );

  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      ClubIdentityFormValues.missingDefaultError(
        gathered: assemble(values),
        translatedIds: ClubDetailsFormFields.translatedIds,
        labels: ClubDetailsFormFields.labels,
      );

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      initialValue: ClubIdentityFormValues.spread(
        values: widget.initialValues,
        textIds: ClubDetailsFormFields.textIds,
        translatedIds: ClubDetailsFormFields.translatedIds,
        languages: widget.languages,
      ),
      onChanged: () => setFormError(null),
      child: FormBody(
        error: formError,
        children: [
          const ClubIdentityTextInput(
            id: ClubDetailsFormFields.nameId,
            label: ClubDetailsFormFields.nameLabel,
            keyboardType: TextInputType.name,
          ),
          const ClubIdentityTextInput(
            id: ClubDetailsFormFields.shortNameId,
            label: ClubDetailsFormFields.shortNameLabel,
            keyboardType: TextInputType.name,
          ),
          TranslatedTextInputs(
            id: ClubDetailsFormFields.taglineId,
            label: ClubDetailsFormFields.taglineLabel,
            languages: widget.languages,
          ),
          const ClubIdentityTextInput(
            id: ClubDetailsFormFields.inquiryEmailId,
            label: ClubDetailsFormFields.inquiryEmailLabel,
            keyboardType: TextInputType.emailAddress,
            validator: ClubIdentityFormValidators.email,
            description: ClubDetailsFormFields.inquiryEmailHelp,
          ),
        ],
      ),
    );
  }
}
