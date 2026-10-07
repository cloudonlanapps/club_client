import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/labeled_form_row.dart';
import 'credit_form_validators.dart';

/// A whole number of credits between [min] and [max], labelled above
/// (club_core#101).
class CreditNumberField extends StatelessWidget {
  const CreditNumberField({
    required this.id,
    required this.label,
    this.min = 1,
    this.max,
    this.enabled = true,
    super.key,
  });

  /// The field's id in the enclosing `ShadForm`.
  final String id;

  /// The label above the input; the cap is added to it when [max] is set.
  final String label;

  /// The smallest number accepted.
  final int min;

  /// The largest number accepted; null for no cap.
  final int? max;

  /// Whether the input accepts text.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: max == null ? label : '$label (max $max)',
      required: true,
      field: ShadInputFormField(
        id: id,
        enabled: enabled,
        keyboardType: TextInputType.number,
        validator: (v) => CreditFormValidators.credits(v, min: min, max: max),
      ),
    );
  }
}
