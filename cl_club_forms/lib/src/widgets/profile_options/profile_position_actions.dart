import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'profile_option_row_frame.dart';

/// The buttons of a position row: move it up, move it down, remove it. A
/// move that has nowhere to go is null and its button is off.
class ProfilePositionActions extends StatelessWidget {
  const ProfilePositionActions({
    required this.enabled,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  /// Whether the buttons respond.
  final bool enabled;

  /// Moves the row up; null for the first row.
  final VoidCallback? onMoveUp;

  /// Moves the row down; null for the last row.
  final VoidCallback? onMoveDown;

  /// Removes the row.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const size = ProfileOptionRowFrame.iconSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadIconButton.ghost(
          enabled: enabled && onMoveUp != null,
          icon: const Icon(LucideIcons.arrowUp, size: size),
          onPressed: onMoveUp,
        ),
        ShadIconButton.ghost(
          enabled: enabled && onMoveDown != null,
          icon: const Icon(LucideIcons.arrowDown, size: size),
          onPressed: onMoveDown,
        ),
        ShadIconButton.ghost(
          enabled: enabled,
          icon: const Icon(LucideIcons.trash2, size: size),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
