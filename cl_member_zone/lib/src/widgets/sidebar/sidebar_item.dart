import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.isCollapsed = false,
    this.badgeCount,
    this.highlightBackground = true,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;
  final int? badgeCount;

  /// When false, the selected state uses bold text only (no background).
  final bool highlightBackground;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final selectedBg = theme.colorScheme.primary.withValues(alpha: 0.1);
    final selectedFg = theme.colorScheme.primary;
    final defaultFg = theme.colorScheme.mutedForeground;

    if (isCollapsed) {
      return Tooltip(
        message: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isSelected && highlightBackground
                  ? selectedBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? selectedFg : defaultFg,
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    // The same dot as the notification bell's.
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.card),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: isSelected && highlightBackground
              ? selectedBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? selectedFg : defaultFg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedFg : theme.colorScheme.foreground,
                ),
              ),
            ),
            if (badgeCount != null && badgeCount! > 0)
              // A count in a muted outline: monochrome, no coloured pill.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: theme.colorScheme.foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
