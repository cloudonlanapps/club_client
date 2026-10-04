import 'package:flutter/widgets.dart';

import 'evaluation_option_buttons.dart';

/// A rating on labelled levels: one button per level, valued 1..n by order.
class EvaluationLevelButtons extends StatelessWidget {
  /// Offers [levels], lowest first, with [value] (or none) chosen.
  const EvaluationLevelButtons({
    required this.levels,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Level labels, lowest first.
  final List<String> levels;

  /// The chosen level's value (1-based), or `null`.
  final int? value;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<int?> onChanged;

  /// Whether taps change the value.
  final bool enabled;

  @override
  Widget build(BuildContext context) => EvaluationOptionButtons<int>(
    options: [for (final (i, l) in levels.indexed) (i + 1, l)],
    selected: value,
    enabled: enabled,
    onChanged: onChanged,
  );
}
