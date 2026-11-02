import 'package:flutter/widgets.dart';

/// Paints diagonal stripes of [color] over [background]: the mark of a
/// session that was planned and called off, in the calendar's week view
/// (club_client#419).
class CancelledStripesPainter extends CustomPainter {
  const CancelledStripesPainter({
    required this.background,
    required this.color,
  });

  /// The fill under the stripes.
  final Color background;

  /// The stripes' colour.
  final Color color;

  /// Distance between two stripes, along the cell's width.
  static const double spacing = 6;

  /// Width of each stripe.
  static const double strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..save()
      ..clipRect(rect)
      ..drawRect(rect, Paint()..color = background);
    final stripe = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    // Lines rising left to right, from below the bottom-left corner until
    // they have crossed the top-right one.
    for (var x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CancelledStripesPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.color != color;
}
