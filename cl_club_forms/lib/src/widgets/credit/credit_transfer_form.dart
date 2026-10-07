import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'credit_date_field.dart';
import 'credit_form_fields.dart';
import 'credit_form_validators.dart';
import 'credit_grant_form.dart';
import 'credit_number_field.dart';
import 'credit_reason_field.dart';

/// Close an account and move what survives a penalty into a new general
/// account (club_core#101): how a programme's credit is settled. Pure UI,
/// driven through a `GlobalKey<CreditTransferFormState>` ([FormContract]).
class CreditTransferForm extends StatefulWidget {
  const CreditTransferForm({
    required this.balance,
    required this.today,
    this.enabled = true,
    super.key,
  });

  /// The account's balance; the penalty cannot exceed it.
  final int balance;

  /// Seeds the new account's window.
  final DateTime today;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<CreditTransferForm> createState() => CreditTransferFormState();
}

/// State of [CreditTransferForm]. Its values are penalty (int, 0 to the
/// balance), validFrom / validUntil (local dates) and reason (trimmed).
class CreditTransferFormState extends State<CreditTransferForm>
    with FormContract<CreditTransferForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      CreditFormValidators.window(
        from: values[CreditFormFields.validFromId] as DateTime,
        until: values[CreditFormFields.validUntilId] as DateTime,
        today: widget.today,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    CreditFormFields.penaltyId: int.parse(
      (values[CreditFormFields.penaltyId] as String).trim(),
    ),
    CreditFormFields.validFromId:
        values[CreditFormFields.validFromId] as DateTime,
    CreditFormFields.validUntilId:
        values[CreditFormFields.validUntilId] as DateTime,
    CreditFormFields.reasonId: (values[CreditFormFields.reasonId] as String)
        .trim(),
  };

  @override
  Widget build(BuildContext context) {
    final from = DateUtils.dateOnly(widget.today);
    return ShadForm(
      key: formKey,
      initialValue: {
        CreditFormFields.penaltyId: '${CreditFormFields.noPenalty}',
        CreditFormFields.validFromId: from,
        CreditFormFields.validUntilId: from.add(
          CreditGrantForm.defaultValidity,
        ),
        CreditFormFields.reasonId: '',
      },
      child: FormBody(
        error: formError,
        children: [
          CreditNumberField(
            id: CreditFormFields.penaltyId,
            label: 'Penalty',
            min: CreditFormFields.noPenalty,
            max: widget.balance,
            enabled: widget.enabled,
          ),
          CreditDateField(
            id: CreditFormFields.validFromId,
            label: 'Valid from',
            enabled: widget.enabled,
          ),
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
