import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

/// The colour of an attendance status, wherever the app shows one: the
/// staff register's status badge, the member's badge on My Calendar and the
/// month view's attendance pie (club_client#415, #416). Attendance is one of
/// the states colour may carry (CLAUDE.md, UI Style Guidelines).
Color attendanceStatusColor(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => Colors.green,
  AttendanceStatus.absent => Colors.red,
  AttendanceStatus.late => Colors.orange,
  AttendanceStatus.onLeave => Colors.blue,
  AttendanceStatus.onLeaveRequested => Colors.amber,
};
