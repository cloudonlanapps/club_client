import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_choice.dart';

/// One choice among [choices] as radio buttons, with Clear once answered.
class EvaluationSingleChoiceInput extends StatelessWidget {
  /// Offers [choices], with [value] (or none) chosen.
  const EvaluationSingleChoiceInput({
    required this.choices,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The choices, in order.
  final List<EvaluationChoice> choices;

  /// The chosen choice's value, or `null`.
  final String? value;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<String?> onChanged;

  /// Whether the choice can change.
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: EvaluationSpacing.optionGap,
    children: [
      ShadRadioGroup<String>(
        // Rebuilt when the host's value changes, so a clear drops it.
        key: ValueKey(value),
        initialValue: value,
        enabled: enabled,
        onChanged: onChanged,
        items: [
          for (final c in choices)
            ShadRadio<String>(value: c.value, label: Text(c.text)),
        ],
      ),
      if (value != null && enabled)
        ShadButton.link(
          padding: EdgeInsets.zero,
          onPressed: () => onChanged(null),
          child: const Text(EvaluationStrings.clear),
        ),
    ],
  );
}
