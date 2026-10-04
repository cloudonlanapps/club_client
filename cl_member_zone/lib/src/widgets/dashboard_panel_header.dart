import 'package:cl_member_zone/src/widgets/dashboard_panel.dart'
    show DashboardPanel;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Title row for a [DashboardPanel] with an icon, title, and optional close
/// affordance.
class DashboardPanelHeader extends StatelessWidget {
  const DashboardPanelHeader({
    required this.title,
    required this.icon,
    this.onClose,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onClose != null)
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.x, size: 16),
            onPressed: onClose,
          ),
      ],
    );
  }
}
