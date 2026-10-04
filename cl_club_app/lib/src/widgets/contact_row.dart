import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One tappable way to reach the club: an icon, a label, the value.
class ContactRow extends StatelessWidget {
  const ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.muted),
                  Text(value, style: theme.textTheme.p),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: theme.colorScheme.mutedForeground,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
