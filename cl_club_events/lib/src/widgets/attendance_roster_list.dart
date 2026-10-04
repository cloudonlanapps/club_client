import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_category.dart';
import '../models/attendance_roster_entry.dart';
import 'attendance_group_section.dart';
import 'attendance_roster_tile.dart';

/// The register's rows: a flat, name-sorted list — marking a member changes
/// only that row in place — or, with [groupByStatus], one card per
/// attendance status (a marked member moves to its group).
class AttendanceRosterList extends StatelessWidget {
  const AttendanceRosterList({
    required this.entries,
    required this.groupByStatus,
    required this.pending,
    required this.onStatusChanged,
    required this.onClear,
    required this.onDisabledTap,
    required this.displayNameResolver,
    required this.isEditable,
    required this.isSuperAdmin,
    super.key,
  });

  final List<AttendanceRosterEntry> entries;
  final bool groupByStatus;
  final Map<String, AttendanceStatus?> pending;
  final void Function(String username, AttendanceStatus status) onStatusChanged;
  final void Function(String username) onClear;
  final void Function(String username) onDisabledTap;
  final String Function(String username) displayNameResolver;
  final bool isEditable;
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    if (!groupByStatus) {
      return ShadCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in entries)
              AttendanceRosterTile(
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
          ],
        ),
      );
    }
    final grouped = groupByAttendanceCategory(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in AttendanceCategory.values)
          if (category != AttendanceCategory.pendingLeave &&
              grouped[category]!.isNotEmpty) ...[
            AttendanceGroupSection(
              category: category,
              entries: grouped[category]!,
              pending: pending,
              onStatusChanged: onStatusChanged,
              onClear: onClear,
              onDisabledTap: onDisabledTap,
              displayNameResolver: displayNameResolver,
              isEditable: isEditable,
              isSuperAdmin: isSuperAdmin,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
