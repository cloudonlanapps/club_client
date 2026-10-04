import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionIcon;

/// A row for a pending leave request with approve/reject actions.
///
/// Follows the same item row pattern as `ManageRequestsDialog`.
class LeaveRequestTile extends StatelessWidget {
  const LeaveRequestTile({
    required this.username,
    required this.displayName,
    required this.event,
    required this.actingUser,
    required this.onApprove,
    required this.onReject,
    this.leaveReason,
    this.isProcessing = false,
    super.key,
  });

  /// The reason the member gave, shown under the request when there is one
  /// (club_core#137).
  final String? leaveReason;

  final String username;
  final String displayName;
  final Event event;
  final UserPrivate actingUser;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final trimmed = leaveReason?.trim();
    final reason = trimmed == null || trimmed.isEmpty ? null : trimmed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.amber.withValues(alpha: 0.15),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Leave requested',
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
                if (reason != null)
                  Text(
                    reason,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (canManageAttendance(event, actingUser)) ...[
            ActionIcon(
              icon: Icons.close,
              enabled: !isProcessing,
              onPressed: onReject,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(width: 4),
            ActionIcon(
              icon: Icons.check,
              enabled: !isProcessing,
              onPressed: onApprove,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
