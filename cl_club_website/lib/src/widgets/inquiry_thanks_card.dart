import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// What an inquiry form turns into once it is sent.
class InquiryThanksCard extends StatelessWidget {
  const InquiryThanksCard({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              LucideIcons.circleCheck,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.h3),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.muted,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
