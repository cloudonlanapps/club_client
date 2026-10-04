import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';

/// One button per option; the selected one is filled, the rest outlined.
/// Tapping the selected option clears the answer, since no question has a
/// default.
class EvaluationOptionButtons<T extends Object> extends StatelessWidget {
  /// Offers [options] (value, label), with [selected] (or none) chosen.
  const EvaluationOptionButtons({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The options as (value, label), in order.
  final List<(T, String)> options;

  /// The chosen value, or `null`.
  final T? selected;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<T?> onChanged;

  /// Whether taps change the value.
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: EvaluationSpacing.optionGap,
    runSpacing: EvaluationSpacing.optionGap,
    children: [
      for (final (value, label) in options)
        if (value == selected)
          ShadButton(
            enabled: enabled,
            onPressed: () => onChanged(null),
            child: Text(label),
          )
        else
          ShadButton.outline(
            enabled: enabled,
            onPressed: () => onChanged(value),
            child: Text(label),
          ),
    ],
  );
}
