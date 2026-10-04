import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/panel_descriptor.dart';
import '../providers/dashboard_prefs.dart';
import '../utils/dashboard_layout.dart';
import 'dashboard_panel.dart';

/// Desktop layout for the dashboard: a [Wrap] of [DashboardPanel]s sized to
/// fit 1, 2, or 3 columns based on [width].
class DashboardDesktopGrid extends ConsumerWidget {
  const DashboardDesktopGrid({
    required this.visible,
    required this.width,
    super.key,
  });

  final List<PanelDescriptor> visible;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cols = width >= DashboardLayout.threeColBreakpoint
        ? 3
        : width >= DashboardLayout.twoColBreakpoint
        ? 2
        : 1;
    final cardWidth = (width - DashboardLayout.gridSpacing * (cols - 1)) / cols;

    return SingleChildScrollView(
      child: Wrap(
        spacing: DashboardLayout.gridSpacing,
        runSpacing: DashboardLayout.gridSpacing,
        children: [
          for (final p in visible)
            SizedBox(
              width: cardWidth,
              child: DashboardPanel(
                title: p.title,
                icon: p.icon,
                maxHeight: DashboardLayout.desktopPanelMaxHeight,
                onClose: () =>
                    ref.read(dashboardPrefsProvider.notifier).closePanel(p.id),
                child: Builder(builder: p.builder),
              ),
            ),
        ],
      ),
    );
  }
}
