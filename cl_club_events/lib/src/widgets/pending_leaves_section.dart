import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_roster_entry.dart';
import 'leave_request_tile.dart';

/// The register's card of pending leave requests, each with approve and
/// reject.
class PendingLeavesSection extends StatelessWidget {
  const PendingLeavesSection({
    required this.event,
    required this.pendingLeaves,
    required this.actingUser,
    required this.displayNameResolver,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final Event event;
  final List<AttendanceRosterEntry> pendingLeaves;
  final UserPrivate actingUser;
  final String Function(String username) displayNameResolver;
  final void Function(String username) onApprove;
  final void Function(String username) onReject;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Pending Leave Requests',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${pendingLeaves.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...pendingLeaves.map(
            (entry) => LeaveRequestTile(
              username: entry.username,
              displayName: displayNameResolver(entry.username),
              event: event,
              actingUser: actingUser,
              leaveReason: entry.leaveReason,
              onApprove: () => onApprove(entry.username),
              onReject: () => onReject(entry.username),
            ),
          ),
        ],
      ),
    );
  }
}
