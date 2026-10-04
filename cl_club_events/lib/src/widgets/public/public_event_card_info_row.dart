import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A single icon-prefixed fact on a public event card: date, time or venue.
///
/// A leading muted icon and body text that wraps naturally.
class PublicEventCardInfoRow extends StatelessWidget {
  const PublicEventCardInfoRow({
    required this.icon,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.foreground,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
