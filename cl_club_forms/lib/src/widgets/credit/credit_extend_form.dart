import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'credit_date_field.dart';
import 'credit_form_fields.dart';
import 'credit_form_validators.dart';
import 'credit_reason_field.dart';

/// Extend an account's validity (club_core#101). Pure UI, driven through a
/// `GlobalKey<CreditExtendFormState>` ([FormContract]).
class CreditExtendForm extends StatefulWidget {
  const CreditExtendForm({
    required this.currentValidUntil,
    this.enabled = true,
    super.key,
  });

  /// The account's validity end today, as a local date.
  final DateTime currentValidUntil;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<CreditExtendForm> createState() => CreditExtendFormState();
}

/// State of [CreditExtendForm]. Its values are validUntil (a local date
/// after the current end) and reason (trimmed).
class CreditExtendFormState extends State<CreditExtendForm>
    with FormContract<CreditExtendForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      CreditFormValidators.extended(
        until: values[CreditFormFields.validUntilId] as DateTime,
        currentValidUntil: widget.currentValidUntil,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    CreditFormFields.validUntilId:
        values[CreditFormFields.validUntilId] as DateTime,
    CreditFormFields.reasonId: (values[CreditFormFields.reasonId] as String)
        .trim(),
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        CreditFormFields.validUntilId: widget.currentValidUntil,
        CreditFormFields.reasonId: '',
      },
      child: FormBody(
        error: formError,
        children: [
          CreditDateField(
            id: CreditFormFields.validUntilId,
            label: 'Valid until',
            enabled: widget.enabled,
          ),
          CreditReasonField(enabled: widget.enabled),
        ],
      ),
    );
  }
}
