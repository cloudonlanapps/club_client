import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';

/// A short range rating as one numbered button per value, [min]..[max],
/// behaving like stars: choosing a value fills every button up to it and
/// outlines the rest; tapping the chosen value again clears it. Every
/// value, the lowest included, is one tap.
class EvaluationRangeButtons extends StatelessWidget {
  /// Buttons for [min]..[max], with [value] (or none) chosen.
  const EvaluationRangeButtons({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Value of the first button.
  final int min;

  /// Value of the last button.
  final int max;

  /// The chosen value, or `null`.
  final int? value;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<int?> onChanged;

  /// Whether taps change the value.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chosen = value;
    return Wrap(
      spacing: EvaluationSpacing.optionGap,
      runSpacing: EvaluationSpacing.optionGap,
      children: [
        for (var v = min; v <= max; v++)
          Semantics(
            label: '${EvaluationStrings.ratePrefix} $v',
            selected: v == chosen,
            child: chosen != null && v <= chosen
                ? ShadButton(
                    enabled: enabled,
                    onPressed: () => onChanged(v == chosen ? null : v),
                    child: Text('$v'),
                  )
                : ShadButton.outline(
                    enabled: enabled,
                    onPressed: () => onChanged(v),
                    child: Text('$v'),
                  ),
          ),
      ],
    );
  }
}
