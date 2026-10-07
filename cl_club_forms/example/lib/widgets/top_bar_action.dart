import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One of the demo's own controls in the top bar: a labelled button, or on
/// a narrow window ([compact]) an icon with the label as its tooltip.
class TopBarAction extends StatelessWidget {
  /// Creates the control.
  const TopBarAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  /// The control's name.
  final String label;

  /// Shown alone when [compact].
  final IconData icon;

  /// Called when the control is pressed.
  final VoidCallback onPressed;

  /// Whether only the icon shows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(tooltip: label, icon: Icon(icon), onPressed: onPressed);
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
