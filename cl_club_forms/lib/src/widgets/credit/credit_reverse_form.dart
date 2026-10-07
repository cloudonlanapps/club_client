import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'credit_form_body.dart';
import 'credit_form_fields.dart';
import 'credit_number_field.dart';
import 'credit_reason_field.dart';

/// Reverse unspent credit on an account (club_core#101). Capped at
/// [unspent]: the server refuses more (R59). Pure UI;
/// [CreditReverseFormState.validate] returns credits (int) and reason.
class CreditReverseForm extends StatefulWidget {
  const CreditReverseForm({required this.unspent, super.key});

  /// What remains unspent on the account.
  final int unspent;

  @override
  State<CreditReverseForm> createState() => CreditReverseFormState();
}

class CreditReverseFormState extends State<CreditReverseForm> {
  final formKey = GlobalKey<ShadFormState>();

  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    return {
      CreditFormFields.creditsId: int.parse(
        (form.value[CreditFormFields.creditsId] as String).trim(),
      ),
      CreditFormFields.reasonId:
          (form.value[CreditFormFields.reasonId] as String).trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CreditFormBody(
      formKey: formKey,
      initialValue: {
        CreditFormFields.creditsId: '${widget.unspent}',
        CreditFormFields.reasonId: '',
      },
      fields: [
        CreditNumberField(
          id: CreditFormFields.creditsId,
          label: 'Credits',
          max: widget.unspent,
        ),
        const CreditReasonField(),
      ],
    );
  }
}
