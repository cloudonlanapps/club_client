import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

import '../utils/attendance_status_color.dart';

/// Colored badge displaying an attendance status label.
///
/// Handles null status as "Not Recorded" with grey styling.
class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({required this.status, super.key});

  /// Attendance status to display. Null means not recorded.
  final AttendanceStatus? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _labelAndColor() {
    final status = this.status;
    if (status == null) return ('Not Recorded', Colors.grey);
    final label = switch (status) {
      AttendanceStatus.present => 'Present',
      AttendanceStatus.absent => 'Absent',
      AttendanceStatus.late => 'Late',
      AttendanceStatus.onLeave => 'On Leave',
      AttendanceStatus.onLeaveRequested => 'Leave Req',
    };
    return (label, attendanceStatusColor(status));
  }
}
