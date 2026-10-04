import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/dashboard_panel_id.dart';
import '../models/panel_descriptor.dart';
import '../providers/dashboard_prefs.dart';
import 'mobile_panel_title.dart';

/// Mobile layout for the dashboard: a multi-open [ShadAccordion] with one
/// item per selected panel. Expansion state is persisted via
/// [dashboardPrefsProvider].
class DashboardMobileAccordion extends ConsumerStatefulWidget {
  const DashboardMobileAccordion({
    required this.visible,
    required this.expanded,
    super.key,
  });

  final List<PanelDescriptor> visible;
  final Set<DashboardPanelId> expanded;

  @override
  ConsumerState<DashboardMobileAccordion> createState() =>
      DashboardMobileAccordionState();
}

class DashboardMobileAccordionState
    extends ConsumerState<DashboardMobileAccordion> {
  late ShadAccordionController<DashboardPanelId> controller;

  @override
  void initState() {
    super.initState();
    controller = ShadAccordionController<DashboardPanelId>.multiple(
      widget.expanded.toList(),
    );
    controller.addListener(handleExpansionChanged);
  }

  @override
  void didUpdateWidget(covariant DashboardMobileAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External pref change: only sync if the controller is meaningfully out
    // of step. This prevents user-driven toggles from being clobbered by our
    // own write-back.
    final controllerSet = controller.value.toSet();
    if (!setEquals(controllerSet, widget.expanded)) {
      controller.value = widget.expanded.toList();
    }
  }

  @override
  void dispose() {
    controller
      ..removeListener(handleExpansionChanged)
      ..dispose();
    super.dispose();
  }

  void handleExpansionChanged() {
    final next = controller.value.toSet();
    unawaited(
      ref.read(dashboardPrefsProvider.notifier).setExpandedOnMobile(next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ShadAccordion<DashboardPanelId>.multiple(
        controller: controller,
        children: [
          for (final p in widget.visible)
            ShadAccordionItem<DashboardPanelId>(
              value: p.id,
              title: MobilePanelTitle(descriptor: p),
              child: Builder(builder: p.builder),
            ),
        ],
      ),
    );
  }
}
