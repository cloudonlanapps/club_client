import 'package:flutter/widgets.dart';

import 'evaluation_range_buttons.dart';
import 'evaluation_range_stepper.dart';

/// A rating over the whole numbers [min]..[max]. Up to [buttonLimit] values
/// show as numbered buttons that fill like stars
/// ([EvaluationRangeButtons]); a longer range steps with − and +
/// ([EvaluationRangeStepper]). There is no default: unanswered until the
/// first tap, and clearing returns it there.
class EvaluationRangeInput extends StatelessWidget {
  /// Rates between [min] and [max], with [value] (or nothing) chosen.
  const EvaluationRangeInput({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The most values shown as buttons.
  static const int buttonLimit = 10;

  /// Lowest value.
  final int min;

  /// Highest value.
  final int max;

  /// The chosen value, or `null`.
  final int? value;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<int?> onChanged;

  /// Whether the input responds.
  final bool enabled;

  /// Whether [min]..[max] shows as buttons rather than a stepper.
  static bool usesButtons(int min, int max) => max - min + 1 <= buttonLimit;

  @override
  Widget build(BuildContext context) => usesButtons(min, max)
      ? EvaluationRangeButtons(
          min: min,
          max: max,
          value: value,
          enabled: enabled,
          onChanged: onChanged,
        )
      : EvaluationRangeStepper(
          min: min,
          max: max,
          value: value,
          enabled: enabled,
          onChanged: onChanged,
        );
}
