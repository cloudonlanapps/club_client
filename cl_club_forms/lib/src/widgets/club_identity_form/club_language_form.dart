import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'club_identity_form_validators.dart';
import 'club_language_form_fields.dart';

/// Pure-UI form for one language code to offer translations in (no SDK / no
/// Riverpod): the code a club adds so that its translatable fields take a
/// text in that language.
///
/// One field. `validate()` returns the code trimmed, under
/// [ClubLanguageFormFields.languageCodeId]; a code that is not a two- or
/// three-letter lowercase code, or that is already in [languages], is
/// refused with a message on the field.
///
/// Fields only: the host supplies the card and the button, and drives the
/// form through a `GlobalKey<ClubLanguageFormState>` ([FormContract]). After
/// it takes a code, the host empties the field with
/// [ClubLanguageFormState.reset].
class ClubLanguageForm extends StatefulWidget {
  const ClubLanguageForm({
    this.languages = const [],
    this.enabled = true,
    this.onSubmitted,
    super.key,
  });

  /// The language codes already listed; adding one of them is refused.
  final List<String> languages;

  /// Whether the field responds.
  final bool enabled;

  /// Called when Enter is pressed in the field; the host points it at its
  /// add action.
  final VoidCallback? onSubmitted;

  @override
  State<ClubLanguageForm> createState() => ClubLanguageFormState();
}

/// State of [ClubLanguageForm]. Its value is `{languageCodeId: String}`,
/// the code trimmed.
class ClubLanguageFormState extends State<ClubLanguageForm>
    with FormContract<ClubLanguageForm> {
  /// Empties the field and clears its message.
  void reset() {
    formKey.currentState?.reset();
    setFormError(null);
  }

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ClubLanguageFormFields.languageCodeId:
        (values[ClubLanguageFormFields.languageCodeId] as String?)?.trim() ??
        '',
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      initialValue: const {ClubLanguageFormFields.languageCodeId: ''},
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: ClubLanguageFormFields.languageCodeLabel,
            required: true,
            field: ShadInputFormField(
              key: ClubLanguageFormFields.languageCodeKey,
              id: ClubLanguageFormFields.languageCodeId,
              placeholder: const Text(
                ClubLanguageFormFields.languageCodePlaceholder,
              ),
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              validator: (value) => ClubIdentityFormValidators.newLanguageCode(
                value,
                widget.languages,
              ),
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
