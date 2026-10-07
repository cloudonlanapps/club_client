import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'credit_form_fields.dart';
import 'credit_form_validators.dart';

/// The reason every credit action records (club_core#101).
class CreditReasonField extends StatelessWidget {
  const CreditReasonField({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadInputFormField(
      id: CreditFormFields.reasonId,
      label: const Text('Reason'),
      keyboardType: TextInputType.text,
      validator: CreditFormValidators.reason,
    );
  }
}
