import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Placeholder section for Events (SDK not ready).
class EventsPlaceholderSection extends StatelessWidget {
  const EventsPlaceholderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Events', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text('Coming soon', style: theme.textTheme.muted),
            ],
          ),
        ],
      ),
    );
  }
}
