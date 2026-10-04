import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'dashboard_panel_header.dart';

/// A bordered, titled card on the configurable dashboard.
///
/// On desktop the body is wrapped in a [SingleChildScrollView] capped at
/// [maxHeight] so the dashboard surface stays a single scroll region and
/// individual panels keep predictable footprints. On mobile (where this
/// widget is rendered inside a [ShadAccordionItem]) [maxHeight] is null and
/// the body grows to its content height.
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.onClose,
    this.maxHeight,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onClose;
  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final body = maxHeight != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight!),
            child: SingleChildScrollView(child: child),
          )
        : child;

    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DashboardPanelHeader(
            title: title,
            icon: icon,
            onClose: onClose,
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }
}
