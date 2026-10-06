import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, TwoColumnGrid;

import '../../models/event_management_action.dart';
import '../../models/event_management_messages.dart';

/// The Event Management card: its title over a two-column grid of
/// [actions]. Renders nothing when there is no action to offer.
class EventManagementCard extends StatelessWidget {
  const EventManagementCard({required this.actions, super.key});

  /// The grid is padded to this many cells, so a lone action keeps its
  /// size.
  static const int minimumCells = 4;

  final List<EventManagementAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(EventManagementMessages.title, style: theme.textTheme.h4),
          const SizedBox(height: 12),
          TwoColumnGrid(
            spacing: 8,
            runSpacing: 8,
            singleColumnBreakpoint: 0,
            children: [
              for (final action in actions)
                ActionButton(
                  label: action.label,
                  onPressed: action.onPressed,
                ),
              for (var i = actions.length; i < minimumCells; i++)
                const IgnorePointer(
                  child: Opacity(opacity: 0, child: ActionButton(label: '')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
