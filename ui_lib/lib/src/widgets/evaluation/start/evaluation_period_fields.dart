import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import 'evaluation_start_form_fields.dart';

/// The review period's two date fields, labels stacked above, keyed by
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
    spacing: EvaluationSpacing.fieldGap,
    children: [
      CLDatePickerFormField(
        id: EvaluationStartFormFields.periodStartId,
        label: const Text(EvaluationStrings.periodStart),
        placeholder: const Text(EvaluationStrings.periodNone),
        initialValue: initialStart,
        enabled: enabled,
        onChanged: (_) => onChanged?.call(),
      ),
      CLDatePickerFormField(
        id: EvaluationStartFormFields.periodEndId,
        label: const Text(EvaluationStrings.periodEnd),
        placeholder: const Text(EvaluationStrings.periodNone),
        initialValue: initialEnd,
        enabled: enabled,
        onChanged: (_) => onChanged?.call(),
      ),
    ],
  );
}
