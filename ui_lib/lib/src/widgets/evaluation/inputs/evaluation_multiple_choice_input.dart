import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../models/evaluation_choice.dart';

/// Any number of [choices] as checkboxes; the answer keeps choice order.
class EvaluationMultipleChoiceInput extends StatelessWidget {
  /// Offers [choices], with [value] chosen.
  const EvaluationMultipleChoiceInput({
    required this.choices,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The choices, in order.
  final List<EvaluationChoice> choices;

  /// The chosen values.
  final List<String> value;

  /// Called with the chosen values in choice order; empty clears.
  final ValueChanged<List<String>> onChanged;

  /// Whether the choices can change.
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: EvaluationSpacing.optionGap,
    children: [
      for (final c in choices)
        ShadCheckbox(
          value: value.contains(c.value),
          enabled: enabled,
          label: Text(c.text),
          onChanged: (on) => onChanged([
            for (final o in choices)
              if (o.value == c.value ? on : value.contains(o.value)) o.value,
          ]),
        ),
    ],
  );
}
