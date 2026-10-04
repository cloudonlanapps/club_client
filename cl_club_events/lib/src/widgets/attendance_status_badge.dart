import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

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
    if (status == null) return ('Not Recorded', Colors.grey);
    return switch (status!) {
      AttendanceStatus.present => ('Present', Colors.green),
      AttendanceStatus.absent => ('Absent', Colors.red),
      AttendanceStatus.late => ('Late', Colors.orange),
      AttendanceStatus.onLeave => ('On Leave', Colors.blue),
      AttendanceStatus.onLeaveRequested => ('Leave Req', Colors.amber),
    };
  }
}
