import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_progress.dart';

/// The mark of how far attendance has been taken: ◐ while partly marked,
/// ✓ once complete, nothing when nothing is marked (club_client#414). Shown
/// in a session's Attendance button and in the staff calendar's day cells.
///
/// Its colours are an attendance state (UI Style Guidelines): amber for
/// partly marked, green for complete, chosen for the theme's brightness so
/// they read on the page, on today's muted cell and on a camp / one-off
/// day's highlight. A [color] given replaces them, as on the selected day.
class AttendanceProgressIcon extends StatelessWidget {
  const AttendanceProgressIcon({
    required this.progress,
    required this.size,
    this.color,
    super.key,
  });

  final AttendanceProgress progress;

  /// The icon's size.
  final double size;

  /// The colour to draw it in, in place of the state's own.
  final Color? color;

  /// Partly marked, in a light theme and in a dark one.
  static const Color partialLight = Color(0xFFB45309);
  static const Color partialDark = Color(0xFFFCD34D);

  /// Complete, in a light theme and in a dark one.
  static const Color completeLight = Color(0xFF15803D);
  static const Color completeDark = Color(0xFF4ADE80);

  /// Size of the mark inside a session's Attendance button.
  static const double buttonSize = 14;

  /// The mark inside [occurrence]'s Attendance button: ◐ while its register
  /// is partly marked, ✓ once complete, none while nothing is.
  static WidgetBuilder? buttonMark(Occurrence occurrence) {
    final progress = AttendanceProgress.of(occurrence);
    if (progress == AttendanceProgress.none) return null;
    return (_) => AttendanceProgressIcon(progress: progress, size: buttonSize);
  }

  /// The colour of [progress] in a theme of [brightness].
  static Color colorOf(AttendanceProgress progress, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (progress) {
      AttendanceProgress.complete => dark ? completeDark : completeLight,
      AttendanceProgress.partial ||
      AttendanceProgress.none => dark ? partialDark : partialLight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (progress) {
      AttendanceProgress.none => null,
      AttendanceProgress.partial => LucideIcons.contrast,
      AttendanceProgress.complete => LucideIcons.circleCheck,
    };
    if (icon == null) return const SizedBox.shrink();
    final brightness = ShadTheme.of(context).brightness;
    return Icon(
      icon,
      size: size,
      color: color ?? colorOf(progress, brightness),
      semanticLabel: switch (progress) {
        AttendanceProgress.none => null,
        AttendanceProgress.partial => 'Attendance partly taken',
        AttendanceProgress.complete => 'Attendance taken',
      },
    );
  }
}
