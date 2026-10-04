import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';

import '../models/attendance_roster_entry.dart';
import 'attendance_member_tile.dart';

/// Builds an [AttendanceMemberTile] from a roster [entry], deriving whether the
/// viewer may mark this member: a super-admin, or a member eligible for the
/// occurrence, or one that already has a record to edit.
///
/// Shared by the grouped and flat (name-sorted) roster layouts so marking
/// behaves identically in both — only the surrounding grouping/order differs.
class AttendanceRosterTile extends StatelessWidget {
  const AttendanceRosterTile({
    required this.entry,
    required this.pending,
    required this.onStatusChanged,
    required this.onClear,
    required this.onDisabledTap,
    required this.displayNameResolver,
    required this.isEditable,
    required this.isSuperAdmin,
    super.key,
  });

  final AttendanceRosterEntry entry;

  /// Optimistic overrides for in-flight mutations (see the roster view).
  final Map<String, AttendanceStatus?> pending;

  final void Function(String username, AttendanceStatus status) onStatusChanged;
  final void Function(String username) onClear;
  final void Function(String username) onDisabledTap;
  final String Function(String username) displayNameResolver;

  /// Whether the toggle is interactive (false outside the attendance windows).
  final bool isEditable;

  /// Whether the viewer is a super-admin (may override eligibility).
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    final hasRecord = isMarkableAttendance(entry.currentStatus);
    final canMark = isSuperAdmin || entry.eligible || hasRecord;
    return AttendanceMemberTile(
      username: entry.username,
      displayName: displayNameResolver(entry.username),
      currentStatus: entry.currentStatus,
      selectedStatus: pending[entry.username],
      hasPending: pending.containsKey(entry.username),
      onStatusChanged: (status) => onStatusChanged(entry.username, status),
      onClear: () => onClear(entry.username),
      onDisabledTap: () => onDisabledTap(entry.username),
      isEditable: isEditable && !entry.trialEnded,
      canMark: canMark,
      blockedCredits: entry.creditBlocked ? entry.usableCredits : null,
      trialEnded: entry.trialEnded,
    );
  }
}
