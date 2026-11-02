import 'dart:math' as math;

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../utils/attendance_status_color.dart';

/// A small pie of a day's attendance on the member's month view: one equal
/// slice per session with a recorded status, in that status's colour
/// (`attendanceStatusColor`, as on the staff register; club_client#416).
/// One session is a full circle.
///
/// The slices are parted, and the pie ringed, in [outlineColor] (the
/// cell's own background), so neighbouring slices of close colours (late
/// orange, leave-requested amber) stay apart and the pie reads on any cell.
class AttendancePie extends StatelessWidget {
  const AttendancePie({
    required this.statuses,
    required this.diameter,
    required this.outlineColor,
    super.key,
  }) : assert(statuses.length > 0, 'A pie needs at least one session.');

  /// The day's recorded statuses, one slice each, clockwise from the top.
  final List<AttendanceStatus> statuses;

  /// The pie's width and height.
  final double diameter;

  /// The colour slices are parted and the pie ringed in.
  final Color outlineColor;

  /// The slices' colours, clockwise from the top.
  List<Color> get sliceColors => [
    for (final status in statuses) attendanceStatusColor(status),
  ];

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diameter,
    child: CustomPaint(
      painter: AttendancePiePainter(
        colors: sliceColors,
        outlineColor: outlineColor,
      ),
    ),
  );
}

/// Paints [AttendancePie]: equal slices of [colors] from the top,
/// clockwise, parted and ringed in [outlineColor].
class AttendancePiePainter extends CustomPainter {
  AttendancePiePainter({required this.colors, required this.outlineColor});

  /// One slice per colour.
  final List<Color> colors;

  /// Separator and ring colour.
  final Color outlineColor;

  /// Width of the separators and the ring, as a share of the diameter.
  static const double outlineShare = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;
    final stroke = math.max(1, size.shortestSide * outlineShare).toDouble();
    final sweep = 2 * math.pi / colors.length;
    const top = -math.pi / 2;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        top + i * sweep,
        sweep,
        true,
        Paint()..color = colors[i],
      );
    }
    final outline = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (colors.length > 1) {
      for (var i = 0; i < colors.length; i++) {
        final angle = top + i * sweep;
        canvas.drawLine(
          center,
          center + Offset(math.cos(angle), math.sin(angle)) * radius,
          outline,
        );
      }
    }
    canvas.drawCircle(center, radius - stroke / 2, outline);
  }

  @override
  bool shouldRepaint(AttendancePiePainter oldDelegate) =>
      oldDelegate.outlineColor != outlineColor ||
      !listEquals(oldDelegate.colors, colors);
}
