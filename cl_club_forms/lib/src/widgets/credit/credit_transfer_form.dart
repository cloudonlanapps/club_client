import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'credit_date_field.dart';
import 'credit_form_body.dart';
import 'credit_form_fields.dart';
import 'credit_form_validators.dart';
import 'credit_grant_form.dart';
import 'credit_number_field.dart';
import 'credit_reason_field.dart';

/// Close an account and move what survives a penalty into a new general
/// account (club_core#101): how a programme's credit is settled. Pure UI;
/// [CreditTransferFormState.validate] returns penalty (int, 0..[balance]),
/// validFrom / validUntil (local dates) and reason.
class CreditTransferForm extends StatefulWidget {
  const CreditTransferForm({
    required this.balance,
    required this.today,
    super.key,
  });

  /// The account's balance; the penalty cannot exceed it.
  final int balance;

  /// Seeds the new account's window.
  final DateTime today;

  @override
  State<CreditTransferForm> createState() => CreditTransferFormState();
}

class CreditTransferFormState extends State<CreditTransferForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? error;

  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final v = form.value;
    final from = v[CreditFormFields.validFromId] as DateTime;
    final until = v[CreditFormFields.validUntilId] as DateTime;
    final windowError = CreditFormValidators.window(
      from: from,
      until: until,
      today: widget.today,
    );
    setState(() => error = windowError);
    if (windowError != null) return null;
    return {
      CreditFormFields.penaltyId: int.parse(
        (v[CreditFormFields.penaltyId] as String).trim(),
      ),
      CreditFormFields.validFromId: from,
      CreditFormFields.validUntilId: until,
      CreditFormFields.reasonId: (v[CreditFormFields.reasonId] as String)
          .trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final from = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
    return CreditFormBody(
      formKey: formKey,
      initialValue: {
        CreditFormFields.penaltyId: '0',
        CreditFormFields.validFromId: from,
        CreditFormFields.validUntilId: from.add(
          CreditGrantForm.defaultValidity,
        ),
        CreditFormFields.reasonId: '',
      },
      error: error,
      fields: [
        CreditNumberField(
          id: CreditFormFields.penaltyId,
          label: 'Penalty',
          min: 0,
          max: widget.balance,
        ),
        const CreditDateField(
          id: CreditFormFields.validFromId,
          label: 'Valid from',
        ),
        const CreditDateField(
          id: CreditFormFields.validUntilId,
          label: 'Valid until',
        ),
        const CreditReasonField(),
      ],
    );
  }
}
