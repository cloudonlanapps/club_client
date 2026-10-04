import 'package:flutter/widgets.dart';

import '../../../constants/evaluation_spacing.dart';

/// Greys [child] when [muted] — a private item in a read-only evaluation,
/// which the member will not see. Monochrome: only the opacity changes.
class EvaluationPrivateShade extends StatelessWidget {
  /// Shades [child] when [muted].
  const EvaluationPrivateShade({
    required this.muted,
    required this.child,
    super.key,
  });

  /// Whether [child] is greyed.
  final bool muted;

  /// The item.
  final Widget child;

  @override
  Widget build(BuildContext context) => muted
      ? Opacity(opacity: EvaluationSpacing.privateOpacity, child: child)
      : child;
}
