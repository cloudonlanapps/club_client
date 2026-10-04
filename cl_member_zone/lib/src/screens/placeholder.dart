import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Placeholder screen for routes not yet fully implemented.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.construction,
            size: 48,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.h3,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}
