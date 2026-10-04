import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'create_event_quick_action.dart';
import 'quick_action_tile.dart';

/// Admin-only fixed strip rendered at the top of the dashboard.
///
/// Single row of four tiles. "Create Event" offers the create flow of each
/// event type the club runs.
class AdminQuickActionsStrip extends StatelessWidget {
  const AdminQuickActionsStrip({
    required this.onCreateUser,
    required this.onCreateGroup,
    required this.onCreateEvent,
    required this.onAnnouncement,
    required this.eventTypes,
    super.key,
  });

  final VoidCallback onCreateUser;
  final VoidCallback onCreateGroup;
  final ValueChanged<EventType> onCreateEvent;
  final VoidCallback onAnnouncement;

  /// The event types the club runs.
  final Set<EventType> eventTypes;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: QuickActionTile(
              icon: LucideIcons.userPlus,
              label: 'Create User',
              onTap: onCreateUser,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: QuickActionTile(
              icon: LucideIcons.usersRound,
              label: 'Create Group',
              onTap: onCreateGroup,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CreateEventQuickAction(
              eventTypes: eventTypes,
              onCreateEvent: onCreateEvent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: QuickActionTile(
              icon: LucideIcons.megaphone,
              label: 'Announcement',
              onTap: onAnnouncement,
            ),
          ),
        ],
      ),
    );
  }
}
