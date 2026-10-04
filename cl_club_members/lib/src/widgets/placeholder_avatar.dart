import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Placeholder avatar when coach image is not available.
class PlaceholderAvatar extends StatelessWidget {
  const PlaceholderAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.muted,
      child: Center(
        child: Icon(
          LucideIcons.user,
          size: 64,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}
