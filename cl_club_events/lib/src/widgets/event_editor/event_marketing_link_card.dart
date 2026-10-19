import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The way from an event's page to its Marketing page (club_client#1):
/// what the website says about the event, with a live preview.
class EventMarketingLinkCard extends StatelessWidget {
  const EventMarketingLinkCard({required this.onOpen, super.key});

  /// Padding inside the card.
  static const double padding = 20;

  /// Opens the Marketing page.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(padding),
      child: Row(
        spacing: padding,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marketing', style: theme.textTheme.h4),
                Text(
                  'What the website shows about this event, with a preview.',
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
          ShadButton.outline(
            onPressed: onOpen,
            leading: const Icon(LucideIcons.megaphone, size: 16),
            child: const Text('Edit marketing'),
          ),
        ],
      ),
    );
  }
}
