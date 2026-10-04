import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// What a landing event section shows when its events cannot be read.
class PublicEventsSectionError extends StatelessWidget {
  const PublicEventsSectionError({
    required this.title,
    required this.error,
    super.key,
  });

  final String title;
  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.h3),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
