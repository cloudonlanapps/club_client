import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';

import '../form/labeled_form_row.dart';
import 'credit_form_validators.dart';

/// A required date in a credit form, labelled above (club_core#101).
class CreditDateField extends StatelessWidget {
  const CreditDateField({
    required this.id,
    required this.label,
    this.enabled = true,
    super.key,
  });

  /// The field's id in the enclosing `ShadForm`.
  final String id;

  /// The label above the picker.
  final String label;

  /// Whether the picker accepts input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: label,
      required: true,
      field: CLDatePickerFormField(
        id: id,
        enabled: enabled,
        validator: CreditFormValidators.requiredDate,
      ),
    );
  }
}
