import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Small bordered status code shown in lieu of action buttons on past
/// occurrences in the member's calendar view.
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

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fg = theme.colorScheme.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
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
