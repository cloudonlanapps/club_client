import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'credit_form_validators.dart';

/// A whole number of credits between [min] and [max] (club_core#101).
class CreditNumberField extends StatelessWidget {
  const CreditNumberField({
    required this.id,
    required this.label,
    this.min = 1,
    this.max,
    super.key,
  });

  final String id;
  final String label;
  final int min;
  final int? max;

  @override
  Widget build(BuildContext context) {
    return ShadInputFormField(
      id: id,
      label: Text(max == null ? label : '$label (max $max)'),
      keyboardType: TextInputType.number,
      validator: (v) => CreditFormValidators.credits(v, min: min, max: max),
    );
  }
}
