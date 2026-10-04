import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One bordered tile inside the Quick Actions panel.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    required this.icon,
    required this.label,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.small.copyWith(fontSize: 11),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}
