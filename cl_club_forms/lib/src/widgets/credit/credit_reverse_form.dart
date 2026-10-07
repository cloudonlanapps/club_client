import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'credit_form_fields.dart';
import 'credit_number_field.dart';
import 'credit_reason_field.dart';

/// Reverse unspent credit on an account (club_core#101). Capped at
/// [unspent]: the server refuses more (R59). Pure UI, driven through a
/// `GlobalKey<CreditReverseFormState>` ([FormContract]).
class CreditReverseForm extends StatefulWidget {
  const CreditReverseForm({
    required this.unspent,
    this.enabled = true,
    super.key,
  });

  /// What remains unspent on the account.
  final int unspent;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<CreditReverseForm> createState() => CreditReverseFormState();
}

/// State of [CreditReverseForm]. Its values are credits (int) and reason
/// (trimmed).
class CreditReverseFormState extends State<CreditReverseForm>
    with FormContract<CreditReverseForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    CreditFormFields.creditsId: int.parse(
      (values[CreditFormFields.creditsId] as String).trim(),
    ),
    CreditFormFields.reasonId: (values[CreditFormFields.reasonId] as String)
        .trim(),
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {
        CreditFormFields.creditsId: '${widget.unspent}',
        CreditFormFields.reasonId: '',
      },
      child: FormBody(
        error: formError,
        children: [
          CreditNumberField(
            id: CreditFormFields.creditsId,
            label: 'Credits',
            max: widget.unspent,
            enabled: widget.enabled,
          ),
          CreditReasonField(enabled: widget.enabled),
        ],
      ),
    );
  }
}
