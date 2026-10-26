import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The bordered box around one row of a profile options list.
class ProfileOptionRowFrame extends StatelessWidget {
  const ProfileOptionRowFrame({required this.child, super.key});

  /// The row's padding inside its border.
  static const double padding = 12;

  /// The rounding of the row's border.
  static const double radius = 8;

  /// The size of the row's action icons.
  static const double iconSize = 16;

  /// What the row holds.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(padding: const EdgeInsets.all(padding), child: child),
    );
  }
}
