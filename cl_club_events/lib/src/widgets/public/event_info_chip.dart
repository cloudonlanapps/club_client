import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One fact of a public event (dates, venue, hours) as a muted icon and
/// text, for the hero card.
class EventInfoChip extends StatelessWidget {
  const EventInfoChip({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.cardForeground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
