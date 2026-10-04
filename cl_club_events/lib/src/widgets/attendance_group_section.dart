import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_category.dart';
import '../models/attendance_roster_entry.dart';
import 'attendance_roster_tile.dart';

/// Groups attendance roster entries under a category header with count badge.
///
/// Follows the same visual pattern as `EnrollmentGroupSection`.
class AttendanceGroupSection extends StatelessWidget {
  const AttendanceGroupSection({
    required this.category,
    required this.entries,
    required this.pending,
    required this.onStatusChanged,
    required this.onClear,
    required this.onDisabledTap,
    required this.displayNameResolver,
    this.isEditable = true,
    this.isSuperAdmin = false,
    super.key,
  });

  final AttendanceCategory category;
  final List<AttendanceRosterEntry> entries;

  /// Optimistic overrides for in-flight mutations — username -> shown status
  /// (a present key with a `null` value is an in-flight clear).
  final Map<String, AttendanceStatus?> pending;

  /// Called when a member's attendance toggle is tapped.
  final void Function(String username, AttendanceStatus status) onStatusChanged;

  /// Called when a member's clear affordance is tapped.
  final void Function(String username) onClear;

  /// Called when a disabled (ineligible) member's toggle is tapped.
  final void Function(String username) onDisabledTap;

  /// Resolves username to display name.
  final String Function(String username) displayNameResolver;

  /// Whether attendance marking is enabled (false when edit window closed).
  final bool isEditable;

  /// Whether the viewer is a super-admin (may override per-occurrence
  /// eligibility and mark ineligible members).
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = category.color;

    if (entries.isEmpty) return const SizedBox.shrink();

    return ShadCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  style: const TextStyle(
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entries.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...entries.map(
            (entry) => AttendanceRosterTile(
              key: ValueKey('attendance-${entry.username}'),
              entry: entry,
              pending: pending,
              onStatusChanged: onStatusChanged,
              onClear: onClear,
              onDisabledTap: onDisabledTap,
              displayNameResolver: displayNameResolver,
              isEditable: isEditable,
              isSuperAdmin: isSuperAdmin,
            ),
          ),
        ],
      ),
    );
  }
}
