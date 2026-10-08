import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';

/// A long range rating as "− value +": each tap steps by one, and the first
/// tap from unanswered — either way — starts at [min]. **Clear** returns it
/// to unanswered; the bounds show beside it.
class EvaluationRangeStepper extends StatelessWidget {
  /// Steps through [min]..[max], from [value] (or unanswered).
  const EvaluationRangeStepper({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Lowest value.
  final int min;

  /// Highest value.
  final int max;

  /// The chosen value, or `null`.
  final int? value;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<int?> onChanged;

  /// Whether the steps and Clear respond.
  final bool enabled;

  /// The callback stepping to [next] (or to [min] while unanswered), or
  /// `null` when it would leave [min]..[max].
  VoidCallback? stepTo(int Function(int current) next) {
    final current = value;
    final target = current == null ? min : next(current);
    if (!enabled || target < min || target > max || target == current) {
      return null;
    }
    return () => onChanged(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context).textTheme;
    final current = value;
    return Wrap(
      spacing: EvaluationSpacing.optionGap,
      runSpacing: EvaluationSpacing.optionGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          label: EvaluationStrings.decrease,
          button: true,
          excludeSemantics: true,
          child: ShadIconButton.outline(
            icon: const Icon(LucideIcons.minus),
            onPressed: stepTo((v) => v - 1),
          ),
        ),
        Text(
          current == null ? EvaluationStrings.notRated : '$current',
          style: current == null ? theme.muted : theme.large,
        ),
        Semantics(
          label: EvaluationStrings.increase,
          button: true,
          excludeSemantics: true,
          child: ShadIconButton.outline(
            icon: const Icon(LucideIcons.plus),
            onPressed: stepTo((v) => v + 1),
          ),
        ),
        Text(
          '$min${EvaluationStrings.rangeSeparator}$max',
          style: theme.muted,
        ),
        if (current != null && enabled)
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => onChanged(null),
            child: const Text(EvaluationStrings.clear),
          ),
      ],
    );
  }
}
