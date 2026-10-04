import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'attendance_status_badge.dart';

/// Whether [status] is a real, admin-markable attendance mark (as opposed to
/// a leave status) — i.e. one that can be cleared back to "not recorded".
bool isMarkableAttendance(AttendanceStatus? status) =>
    status == AttendanceStatus.present ||
    status == AttendanceStatus.absent ||
    status == AttendanceStatus.late;

/// A single member row in the attendance roster with inline status toggle.
///
/// Shows avatar, display name, username, current status badge, and a
/// segmented toggle (Present / Absent / Late) when [isEditable] is true.
/// Members on leave have the toggle hidden — their status is managed via
/// leave approval, not direct marking.
///
/// When the member is not eligible for this occurrence and the viewer is not
/// a super-admin ([canMark] is false), the toggle renders disabled and tapping
/// it calls [onDisabledTap] (the host shows an explanatory toast).
///
/// Clearing a mark ([onClear]) has two affordances: re-tapping the
/// already-selected segment, or the explicit clear (✕) button that appears
/// whenever there is a mark to remove.
class AttendanceMemberTile extends StatelessWidget {
  const AttendanceMemberTile({
    required this.username,
    required this.displayName,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.onClear,
    required this.onDisabledTap,
    this.selectedStatus,
    this.hasPending = false,
    this.isEditable = true,
    this.canMark = true,
    this.blockedCredits,
    this.trialEnded = false,
    super.key,
  });

  final String username;
  final String displayName;

  /// Server-side attendance status (null = not recorded).
  final AttendanceStatus? currentStatus;

  /// Optimistic status shown while a mutation is in flight. Only consulted when
  /// [hasPending] is true (a `null` value then means an in-flight clear).
  final AttendanceStatus? selectedStatus;

  /// Whether [selectedStatus] is an active optimistic override. Distinguishes a
  /// pending clear (`hasPending` true, `selectedStatus` null) from "no
  /// override" (`hasPending` false), since both carry a null [selectedStatus].
  final bool hasPending;

  /// Called when admin taps a toggle segment.
  final void Function(AttendanceStatus status) onStatusChanged;

  /// Called when admin taps the clear affordance.
  final VoidCallback onClear;

  /// Called when admin taps a disabled toggle (member ineligible, not sudo).
  final VoidCallback onDisabledTap;

  /// Whether the segmented toggle is enabled (false when edit window closed).
  final bool isEditable;

  /// Whether this viewer may mark this member for this occurrence. False when
  /// the member is ineligible for the occurrence and the viewer is not a
  /// super-admin and there is no existing record to edit.
  final bool canMark;

  /// Set when a mark would charge a member who cannot pay (club_core#99):
  /// the toggle is greyed out with a chip showing this many credits beside
  /// it, which opens the member's credit view.
  final int? blockedCredits;

  /// This session's mark ended the member's trial (club_core#98): a flag,
  /// and no toggle.
  final bool trialEnded;

  /// Whether this member is on leave (approved or pending).
  bool get isOnLeave =>
      currentStatus == AttendanceStatus.onLeave ||
      currentStatus == AttendanceStatus.onLeaveRequested;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final effectiveStatus = hasPending ? selectedStatus : currentStatus;

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
            backgroundColor: theme.colorScheme.muted,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
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
                  username,
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (trialEnded) ...[
            Semantics(
              label: 'Trial ended',
              child: Icon(
                LucideIcons.flag,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isOnLeave)
            AttendanceStatusBadge(status: currentStatus)
          else if (isEditable)
            buildEditControls(effectiveStatus)
          else
            AttendanceStatusBadge(
              status: effectiveStatus,
            ),
        ],
      ),
    );
  }

  Widget buildEditControls(AttendanceStatus? effective) {
    if (blockedCredits != null) {
      // No usable credit and the session is not charged yet: marking would
      // be refused. The chip says why and opens the credit view.
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          CreditChip(username: username, credits: blockedCredits),
          buildStatusToggle(effective, enabled: false, onDisabled: null),
        ],
      );
    }
    if (!canMark) {
      // Ineligible member, non-super-admin viewer: show a disabled toggle that
      // explains itself on tap rather than silently doing nothing.
      return buildStatusToggle(
        effective,
        enabled: false,
        onDisabled: onDisabledTap,
      );
    }
    final showClear = isMarkableAttendance(effective);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildStatusToggle(effective, enabled: true, onDisabled: null),
        if (showClear) ...[
          const SizedBox(width: 6),
          buildClearButton(),
        ],
      ],
    );
  }

  Widget buildStatusToggle(
    AttendanceStatus? effective, {
    required bool enabled,
    required VoidCallback? onDisabled,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildToggleButton(
          label: 'P',
          tooltip: 'Present',
          status: AttendanceStatus.present,
          isActive: effective == AttendanceStatus.present,
          color: Colors.green,
          enabled: enabled,
          onDisabled: onDisabled,
        ),
        const SizedBox(width: 4),
        buildToggleButton(
          label: 'A',
          tooltip: 'Absent',
          status: AttendanceStatus.absent,
          isActive: effective == AttendanceStatus.absent,
          color: Colors.red,
          enabled: enabled,
          onDisabled: onDisabled,
        ),
        const SizedBox(width: 4),
        buildToggleButton(
          label: 'L',
          tooltip: 'Late',
          status: AttendanceStatus.late,
          isActive: effective == AttendanceStatus.late,
          color: Colors.orange,
          enabled: enabled,
          onDisabled: onDisabled,
        ),
      ],
    );
  }

  Widget buildToggleButton({
    required String label,
    required String tooltip,
    required AttendanceStatus status,
    required bool isActive,
    required Color color,
    required bool enabled,
    required VoidCallback? onDisabled,
  }) {
    final activeColor = enabled ? color : Colors.grey;
    return Tooltip(
      message: enabled
          ? (isActive ? '$tooltip (tap to clear)' : tooltip)
          : onDisabled == null
          ? tooltip
          : '$tooltip (not enrolled for this session)',
      child: GestureDetector(
        // Re-tapping the already-selected segment clears the mark; tapping a
        // different segment sets it.
        onTap: enabled
            ? (isActive ? onClear : () => onStatusChanged(status))
            : onDisabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(
                color: isActive
                    ? activeColor
                    : Colors.grey.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? activeColor : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildClearButton() {
    return Tooltip(
      message: 'Clear',
      child: GestureDetector(
        onTap: onClear,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.close, size: 14, color: Colors.grey),
        ),
      ),
    );
  }
}
