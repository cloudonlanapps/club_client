import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Error display for content section.
///
/// Shows a user-friendly error message without exposing technical details.
/// The [error] parameter is only used for debug logging, not displayed to
/// users.
class ErrorContent extends StatelessWidget {
  const ErrorContent({required this.error, required this.title, super.key});
  final String error;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 48,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We encountered an issue loading this content. Please try '
                'again later.',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
