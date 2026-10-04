import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A ghost icon button with a semantic [label].
class EvaluationIconAction extends StatelessWidget {
  /// Shows [icon]; disabled when [onPressed] is `null`.
  const EvaluationIconAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// What the action does, for assistive technology.
  final String label;

  /// The icon.
  final IconData icon;

  /// Runs the action; `null` disables it.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: ShadIconButton.ghost(icon: Icon(icon), onPressed: onPressed),
  );
}
