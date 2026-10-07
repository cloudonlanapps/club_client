import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';

import '../event_schedule/labeled_form_row.dart';
import 'credit_form_validators.dart';

/// A required date in a credit form, labelled above (club_core#101).
class CreditDateField extends StatelessWidget {
  const CreditDateField({required this.id, required this.label, super.key});

  final String id;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: label,
      required: true,
      field: CLDatePickerFormField(
        id: id,
        validator: CreditFormValidators.requiredDate,
      ),
    );
  }
}
