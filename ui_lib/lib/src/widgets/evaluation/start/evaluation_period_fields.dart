import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../constants/form_spacing.dart';
import '../../labeled_form_row.dart';
import 'evaluation_start_form_fields.dart';

/// The review period's two date fields, each under its label row, keyed by
/// [EvaluationStartFormFields.periodStartId] and
/// [EvaluationStartFormFields.periodEndId]. Used inside a `ShadForm`.
class EvaluationPeriodFields extends StatelessWidget {
  /// The two fields, seeded with [initialStart] and [initialEnd].
  const EvaluationPeriodFields({
    this.initialStart,
    this.initialEnd,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The seeded first day.
  final DateTime? initialStart;

  /// The seeded last day.
  final DateTime? initialEnd;

  /// Whether the dates can change.
  final bool enabled;

  /// Called after either date changes.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FormSpacing.rowGap,
    children: [
      LabeledFormRow(
        label: EvaluationStrings.periodStart,
        field: CLDatePickerFormField(
          id: EvaluationStartFormFields.periodStartId,
          placeholder: const Text(EvaluationStrings.periodNone),
          initialValue: initialStart,
          enabled: enabled,
          onChanged: (_) => onChanged?.call(),
        ),
      ),
      LabeledFormRow(
        label: EvaluationStrings.periodEnd,
        field: CLDatePickerFormField(
          id: EvaluationStartFormFields.periodEndId,
          placeholder: const Text(EvaluationStrings.periodNone),
          initialValue: initialEnd,
          enabled: enabled,
          onChanged: (_) => onChanged?.call(),
        ),
      ),
    ],
  );
}
