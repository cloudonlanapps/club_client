import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

import 'attendance_roster_entry.dart';

/// Logical grouping of attendance statuses for display in the roster.
enum AttendanceCategory {
  pendingLeave('Leave Requested', Colors.amber),
  present('Present', Colors.green),
  late('Late', Colors.orange),
  absent('Absent', Colors.red),
  onLeave('On Leave', Colors.blue),
  notRecorded('Not Recorded', Colors.grey);

  const AttendanceCategory(this.label, this.color);

  final String label;
  final Color color;
}

/// Returns the display category for a given attendance status.
///
/// Null status means no attendance has been recorded yet.
AttendanceCategory attendanceCategoryFor(AttendanceStatus? status) {
  if (status == null) return AttendanceCategory.notRecorded;
  return switch (status) {
    AttendanceStatus.present => AttendanceCategory.present,
    AttendanceStatus.absent => AttendanceCategory.absent,
    AttendanceStatus.late => AttendanceCategory.late,
    AttendanceStatus.onLeave => AttendanceCategory.onLeave,
    AttendanceStatus.onLeaveRequested => AttendanceCategory.pendingLeave,
  };
}

/// Groups roster entries by attendance category.
///
/// Returns a map with every category key present (empty list if no entries).
Map<AttendanceCategory, List<AttendanceRosterEntry>> groupByAttendanceCategory(
  List<AttendanceRosterEntry> entries,
) {
  final result = <AttendanceCategory, List<AttendanceRosterEntry>>{
    for (final cat in AttendanceCategory.values) cat: [],
  };

  for (final entry in entries) {
    final category = attendanceCategoryFor(entry.currentStatus);
    result[category]!.add(entry);
  }

  return result;
}
