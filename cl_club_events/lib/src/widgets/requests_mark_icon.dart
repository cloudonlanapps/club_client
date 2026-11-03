import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_progress.dart';
import '../models/requests_mark.dart';
import 'attendance_progress_icon.dart';

/// The mark inside a session's Manage requests action (club_client#439):
/// ⏳ while a request awaits a decision, ◐ when members are on approved
/// leave and nothing is waiting, nothing otherwise. Drawn in the partly
/// marked attendance colour, as the Attendance button's ◐ is.
class RequestsMarkIcon extends StatelessWidget {
  const RequestsMarkIcon({required this.mark, required this.size, super.key});

  final RequestsMark mark;
  final double size;

  /// The mark inside [occurrence]'s Manage requests action, or null when
  /// there is nothing to show.
  static WidgetBuilder? buttonMark(Occurrence occurrence) {
    final mark = RequestsMark.of(occurrence);
    if (mark == RequestsMark.none) return null;
    return (_) => RequestsMarkIcon(
      mark: mark,
      size: AttendanceProgressIcon.buttonSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (mark) {
      RequestsMark.none => null,
      RequestsMark.pending => LucideIcons.hourglass,
      RequestsMark.approvedLeave => LucideIcons.contrast,
    };
    if (icon == null) return const SizedBox.shrink();
    return Icon(
      icon,
      size: size,
      color: AttendanceProgressIcon.colorOf(
        AttendanceProgress.partial,
        ShadTheme.of(context).brightness,
      ),
      semanticLabel: switch (mark) {
        RequestsMark.none => null,
        RequestsMark.pending => 'Requests waiting',
        RequestsMark.approvedLeave => 'Members on leave',
      },
    );
  }
}
