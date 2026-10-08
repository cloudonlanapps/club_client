import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'inquiry_choice.dart';
import 'inquiry_form_copy.dart';
import 'inquiry_form_fields.dart';
import 'inquiry_form_validators.dart';
import 'inquiry_honeypot_field.dart';

/// Pure-UI public inquiry form (no SDK / no Riverpod): contact, or an
/// expression of interest.
///
/// Both kinds ask for a name, an email, a phone and a message, and differ in
/// wording ([copy]), in the extra questions ([choices]) and in whether the
/// message is required ([messageRequired]), so they are one form.
///
/// It also carries the honeypot ([InquiryHoneypotField]), which no visitor
/// sees and whose value is part of what `validate()` returns.
///
/// The form owns no title, buttons or thank-you: the host drives it through
/// a `GlobalKey<InquiryFormState>`, calling `validate()` from its Send
/// action ([FormContract]).
class InquiryForm extends StatefulWidget {
  const InquiryForm({
    required this.copy,
    this.choices = const [],
    this.messageRequired = true,
    this.enabled = true,
    super.key,
  });

  /// The labels, placeholders and messages, from the club's copy.
  final InquiryFormCopy copy;

  /// The extra questions, one select each, between the phone and the
  /// message. None is required.
  final List<InquiryChoice> choices;

  /// Whether a message is required. A contact form is a message; an interest
  /// form is a set of answers with an optional note.
  final bool messageRequired;

  /// Whether the fields respond; the host turns it off while it sends.
  final bool enabled;

  @override
  State<InquiryForm> createState() => InquiryFormState();
}

/// State of [InquiryForm]. Its values are keyed by the ids of
/// [InquiryFormFields]: the four texts trimmed, the honeypot as filled, and
/// under [InquiryFormFields.answersId] the answered questions by key.
class InquiryFormState extends State<InquiryForm>
    with FormContract<InquiryForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    for (final id in [
      InquiryFormFields.nameId,
      InquiryFormFields.emailId,
      InquiryFormFields.phoneId,
      InquiryFormFields.messageId,
    ])
      id: (values[id] as String?)?.trim() ?? '',
    InquiryFormFields.answersId: <String, String>{
      for (final choice in widget.choices)
        if (values[InquiryFormFields.answerId(choice.key)]
            case final String answer)
          choice.key: answer,
    },
    InquiryFormFields.honeypotId:
        values[InquiryFormFields.honeypotId] as String? ?? '',
  };

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      initialValue: const {
        InquiryFormFields.nameId: '',
        InquiryFormFields.emailId: '',
        InquiryFormFields.phoneId: '',
        InquiryFormFields.messageId: '',
        InquiryFormFields.honeypotId: '',
      },
      onChanged: () => setFormError(null),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormBody(
            error: formError,
            children: [
              LabeledFormRow(
                label: copy.nameLabel,
                required: true,
                field: ShadInputFormField(
                  id: InquiryFormFields.nameId,
                  placeholder: Text(copy.namePlaceholder),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) => InquiryFormValidators.name(
                    value,
                    requiredMessage: copy.nameRequired,
                  ),
                ),
              ),
              LabeledFormRow(
                label: copy.emailLabel,
                required: true,
                field: ShadInputFormField(
                  id: InquiryFormFields.emailId,
                  placeholder: Text(copy.emailPlaceholder),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  validator: (value) => InquiryFormValidators.email(
                    value,
                    requiredMessage: copy.emailRequired,
                    invalidMessage: copy.emailInvalid,
                  ),
                ),
              ),
              LabeledFormRow(
                label: copy.phoneLabel,
                field: ShadInputFormField(
                  id: InquiryFormFields.phoneId,
                  placeholder: Text(copy.phonePlaceholder),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: InquiryFormValidators.phone,
                ),
              ),
              for (final choice in widget.choices)
                LabeledFormRow(
                  label: choice.label,
                  field: ShadSelectFormField<String>(
                    id: InquiryFormFields.answerId(choice.key),
                    placeholder: Text(choice.placeholder),
                    options: [
                      for (final option in choice.options.entries)
                        ShadOption(
                          value: option.key,
                          child: Text(option.value),
                        ),
                    ],
                    selectedOptionBuilder: (context, value) =>
                        Text(choice.options[value] ?? value),
                  ),
                ),
              LabeledFormRow(
                label: copy.messageLabel,
                required: widget.messageRequired,
                field: ShadInputFormField(
                  id: InquiryFormFields.messageId,
                  placeholder: Text(copy.messagePlaceholder),
                  minLines: InquiryFormFields.messageMinLines,
                  maxLines: InquiryFormFields.messageMaxLines,
                  validator: (value) => InquiryFormValidators.message(
                    value,
                    required: widget.messageRequired,
                    requiredMessage: copy.messageRequired,
                  ),
                ),
              ),
            ],
          ),
          const InquiryHoneypotField(),
        ],
      ),
    );
  }
}
