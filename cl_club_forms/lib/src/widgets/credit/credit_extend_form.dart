import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'credit_date_field.dart';
import 'credit_form_body.dart';
import 'credit_form_fields.dart';
import 'credit_reason_field.dart';

/// Extend an account's validity (club_core#101). Pure UI;
/// [CreditExtendFormState.validate] returns validUntil (a local date after
/// [currentValidUntil]) and reason, or null.
class CreditExtendForm extends StatefulWidget {
  const CreditExtendForm({required this.currentValidUntil, super.key});

  /// The account's validity end today, as a local date.
  final DateTime currentValidUntil;

  @override
  State<CreditExtendForm> createState() => CreditExtendFormState();
}

class CreditExtendFormState extends State<CreditExtendForm> {
  final formKey = GlobalKey<ShadFormState>();
  String? error;

  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final until = form.value[CreditFormFields.validUntilId] as DateTime;
    final extendError = until.isAfter(widget.currentValidUntil)
        ? null
        : 'Pick a date after the current end';
    setState(() => error = extendError);
    if (extendError != null) return null;
    return {
      CreditFormFields.validUntilId: until,
      CreditFormFields.reasonId:
          (form.value[CreditFormFields.reasonId] as String).trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CreditFormBody(
      formKey: formKey,
      initialValue: {
        CreditFormFields.validUntilId: widget.currentValidUntil,
        CreditFormFields.reasonId: '',
      },
      error: error,
      fields: const [
        CreditDateField(
          id: CreditFormFields.validUntilId,
          label: 'Valid until',
        ),
        CreditReasonField(),
      ],
    );
  }
}
