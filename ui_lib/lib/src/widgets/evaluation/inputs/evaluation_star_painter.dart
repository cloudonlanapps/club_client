import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints a five-pointed star: filled with [color] when [filled], otherwise
/// outlined in it.
class EvaluationStarPainter extends CustomPainter {
  /// Paints one star.
  const EvaluationStarPainter({required this.filled, required this.color});

  /// Points of the star.
  static const int points = 5;

  /// Inner radius as a share of the outer one.
  static const double innerRatio = 0.45;

  /// Outline width as a share of the size.
  static const double strokeRatio = 0.07;

  /// Whether the star is filled.
  final bool filled;

  /// Fill or outline colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final stroke = size.shortestSide * strokeRatio;
    final outer = r - stroke / 2;
    final centre = size.center(Offset.zero);
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : outer * innerRatio;
      final angle = -math.pi / 2 + i * math.pi / points;
      final p = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(EvaluationStarPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.color != color;
}
