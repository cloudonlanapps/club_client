import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import 'evaluation_star_painter.dart';

/// A rating as stars valued [min]..[max]: the chosen star and those below it
/// are filled, the rest outlined. Tapping the chosen star clears it.
class EvaluationStarInput extends StatelessWidget {
  /// Stars for [min]..[max], with [value] (or none) chosen.
  const EvaluationStarInput({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Value of the first star.
  final int min;

  /// Value of the last star.
  final int max;

  /// The chosen value, or `null`.
  final int? value;

  /// Called with the new value, or `null` when cleared.
  final ValueChanged<int?> onChanged;

  /// Whether taps change the value.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    final chosen = value;
    return Wrap(
      spacing: EvaluationSpacing.optionGap,
      children: [
        for (var v = min; v <= max; v++)
          Semantics(
            label: '${EvaluationStrings.ratePrefix} $v',
            selected: v == chosen,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? () => onChanged(v == chosen ? null : v) : null,
              child: MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: CustomPaint(
                  size: const Size.square(EvaluationSpacing.starSize),
                  painter: EvaluationStarPainter(
                    filled: chosen != null && v <= chosen,
                    color: chosen != null && v <= chosen
                        ? colors.foreground
                        : colors.mutedForeground,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
