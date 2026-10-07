import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/labeled_form_row.dart';
import 'credit_form_fields.dart';
import 'credit_form_validators.dart';

/// The reason every credit action records, labelled above (club_core#101).
class CreditReasonField extends StatelessWidget {
  const CreditReasonField({this.enabled = true, super.key});

  /// The label above the input.
  static const String label = 'Reason';

  /// Whether the input accepts text.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: label,
      required: true,
      field: ShadInputFormField(
        id: CreditFormFields.reasonId,
        enabled: enabled,
        keyboardType: TextInputType.text,
        validator: CreditFormValidators.reason,
      ),
    );
  }
}
