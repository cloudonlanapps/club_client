import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';

import '../../utils/attendance_status_color.dart';

/// Small bordered status code shown in lieu of action buttons on past
/// occurrences in the member's calendar view, in its status's colour
/// (`attendanceStatusColor`, as on the staff register; club_client#415).
class AttendanceBadge extends StatelessWidget {
  const AttendanceBadge({required this.status, super.key});

  final AttendanceStatus status;

  static String codeFor(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present => 'P',
    AttendanceStatus.absent => 'A',
    AttendanceStatus.late => 'L',
    AttendanceStatus.onLeave => 'OL',
    AttendanceStatus.onLeaveRequested => 'LR',
  };

  /// The colour the badge draws its code, border and tint in.
  Color get color => attendanceStatusColor(status);

  @override
  Widget build(BuildContext context) {
    final fg = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        border: Border.all(color: fg, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        codeFor(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
