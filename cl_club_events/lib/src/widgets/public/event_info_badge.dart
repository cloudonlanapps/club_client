import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One fact of a public event (dates, timings, venue) as an icon, label and
/// value.
/// On mobile, displays as a compact chip (icon + value).
/// On desktop, displays as a vertical card (icon, label, value stacked).
class EventInfoBadge extends StatelessWidget {
  const EventInfoBadge({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.isMobile = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final badgeColor = theme.colorScheme.foreground;

    // Mobile: chip style.
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Desktop: vertical card layout
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: badgeColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: badgeColor.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
