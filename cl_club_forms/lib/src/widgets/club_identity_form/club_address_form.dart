import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'club_address_form_fields.dart';
import 'club_identity_form_values.dart';
import 'club_identity_text_input.dart';
import 'translated_text_inputs.dart';

/// Pure-UI section form for the club's postal address (no SDK / no Riverpod).
///
/// Plain fields are `String`s; translatable fields are `FormTranslatedText`s,
/// a default plus one text per language of [languages]. Each input is its
/// own form field; `validate()` gathers them back into one value per field
/// id of [ClubAddressFormFields], every text trimmed and empty translations
/// dropped. A translation without its default text is refused with a
/// form-level message.
///
/// Fields only: the host supplies the card and the buttons, and drives the
/// form through a `GlobalKey<ClubAddressFormState>` ([FormContract]).
class ClubAddressForm extends StatefulWidget {
  const ClubAddressForm({
    required this.initialValues,
    this.languages = const [],
    this.enabled = true,
    super.key,
  });

  /// Keyed by the ids of [ClubAddressFormFields]: a `String` for each plain
  /// text field, a `FormTranslatedText` for each translatable one; missing
  /// reads empty. Other keys are ignored.
  final Map<String, dynamic> initialValues;

  /// The language codes each translatable field offers a translation in.
  final List<String> languages;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ClubAddressForm> createState() => ClubAddressFormState();
}

/// State of [ClubAddressForm]. Its values are keyed by the ids of
/// [ClubAddressFormFields].
class ClubAddressFormState extends State<ClubAddressForm>
    with FormContract<ClubAddressForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      ClubIdentityFormValues.gather(
        raw: values,
        initialValues: widget.initialValues,
        textIds: ClubAddressFormFields.textIds,
        translatedIds: ClubAddressFormFields.translatedIds,
        languages: widget.languages,
      );

  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      ClubIdentityFormValues.missingDefaultError(
        gathered: assemble(values),
        translatedIds: ClubAddressFormFields.translatedIds,
        labels: ClubAddressFormFields.labels,
      );

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      initialValue: ClubIdentityFormValues.spread(
        values: widget.initialValues,
        textIds: ClubAddressFormFields.textIds,
        translatedIds: ClubAddressFormFields.translatedIds,
        languages: widget.languages,
      ),
      onChanged: () => setFormError(null),
      child: FormBody(
        error: formError,
        children: [
          TranslatedTextInputs(
            id: ClubAddressFormFields.addressId,
            label: ClubAddressFormFields.addressLabel,
            languages: widget.languages,
            keyboardType: TextInputType.streetAddress,
          ),
          TranslatedTextInputs(
            id: ClubAddressFormFields.addressLine2Id,
            label: ClubAddressFormFields.addressLine2Label,
            languages: widget.languages,
            keyboardType: TextInputType.streetAddress,
          ),
          TranslatedTextInputs(
            id: ClubAddressFormFields.cityId,
            label: ClubAddressFormFields.cityLabel,
            languages: widget.languages,
            keyboardType: TextInputType.streetAddress,
          ),
          TranslatedTextInputs(
            id: ClubAddressFormFields.stateId,
            label: ClubAddressFormFields.stateLabel,
            languages: widget.languages,
            keyboardType: TextInputType.streetAddress,
          ),
          const ClubIdentityTextInput(
            id: ClubAddressFormFields.postalCodeId,
            label: ClubAddressFormFields.postalCodeLabel,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
