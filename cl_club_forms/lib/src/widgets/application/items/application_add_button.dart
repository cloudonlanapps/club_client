import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'application_item_frame.dart';

/// The outline button under an application list that adds to it.
class ApplicationAddButton extends StatelessWidget {
  const ApplicationAddButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  /// The button's text.
  final String label;

  /// Whether the button responds.
  final bool enabled;

  /// Adds the item.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ShadButton.outline(
        enabled: enabled,
        leading: const Icon(
          LucideIcons.plus,
          size: ApplicationItemFrame.iconSize,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
