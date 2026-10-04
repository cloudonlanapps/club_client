import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/dashboard_panel_id.dart';
import '../models/panel_descriptor.dart';
import '../providers/dashboard_prefs.dart';
import 'panel_toggle_row.dart';

/// Modal dialog for adding/removing panels on the configurable dashboard.
///
/// Shows one [PanelToggleRow] per available panel. Toggling a row writes
/// through to [dashboardPrefsProvider]. Caller surfaces this with
/// [showAddPanelDialog].
class AddPanelDialog extends ConsumerWidget {
  const AddPanelDialog({required this.available, super.key});

  /// Panels visible to the current user, in fixed display order.
  final List<PanelDescriptor> available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(dashboardPrefsProvider).valueOrNull;
    final selected = prefs?.selected ?? const <DashboardPanelId>{};

    return ShadDialog(
      title: const Text('Manage panels'),
      description: const Text(
        'Pick which panels appear on your dashboard. '
        'They are shown in a fixed order.',
      ),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in available)
              PanelToggleRow(
                descriptor: p,
                checked: selected.contains(p.id),
                onChanged: (value) {
                  final next = selected.toSet();
                  if (value) {
                    next.add(p.id);
                  } else {
                    next.remove(p.id);
                  }
                  unawaited(
                    ref.read(dashboardPrefsProvider.notifier).setSelected(next),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Convenience wrapper around [showShadDialog] that surfaces an
/// [AddPanelDialog] with the given available panels.
Future<void> showAddPanelDialog(
  BuildContext context, {
  required List<PanelDescriptor> available,
}) {
  return showShadDialog<void>(
    context: context,
    builder: (ctx) => AddPanelDialog(available: available),
  );
}
