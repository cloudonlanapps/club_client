import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/panel_descriptor.dart';
import 'add_panel_dialog.dart';

/// Top row of the dashboard surface: title on the left, "+" manage button
/// on the right.
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({required this.allowed, super.key});

  /// Panels the current user is allowed to see; passed to the manage dialog.
  final List<PanelDescriptor> allowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'Dashboard',
            style: theme.textTheme.h2.copyWith(fontSize: 22),
          ),
        ),
        ShadIconButton.outline(
          icon: const Icon(LucideIcons.plus, size: 16),
          onPressed: () => showAddPanelDialog(context, available: allowed),
        ),
      ],
    );
  }
}
