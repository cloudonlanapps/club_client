import 'package:flutter/material.dart';

/// Stamp badge widget - eye-catching rotated badge for hero sections.
///
/// Used for highlighting special content like "NEW BATCH", "SUMMER CAMP",
/// etc., and for an evaluation's status stamp. The text is shown in
/// capitals; the colours default to the website's gold on black.
class StampBadge extends StatelessWidget {
  /// A badge reading [text], drawn in [background] and [foreground].
  const StampBadge({
    required this.text,
    this.background = defaultBackground,
    this.foreground = defaultForeground,
    super.key,
  });

  /// The badge's text, shown in capitals.
  final String text;

  /// The badge's fill.
  final Color background;

  /// The text's colour.
  final Color foreground;

  /// The website's gold fill.
  static const Color defaultBackground = Color(0xFFFFD700);

  /// The website's text colour.
  static const Color defaultForeground = Colors.black87;

  /// The tilt, in radians.
  static const double tilt = -0.05;

  /// Horizontal padding around the text.
  static const double horizontalPadding = 16;

  /// Vertical padding around the text.
  static const double verticalPadding = 8;

  /// Corner radius.
  static const double cornerRadius = 4;

  /// Opacity of the drop shadow.
  static const double shadowAlpha = 0.2;

  /// Blur of the drop shadow.
  static const double shadowBlur = 8;

  /// Vertical offset of the drop shadow.
  static const double shadowOffset = 4;

  /// Size of the text.
  static const double fontSize = 14;

  /// Letter spacing of the text.
  static const double letterSpacing = 1;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowAlpha),
              blurRadius: shadowBlur,
              offset: const Offset(0, shadowOffset),
            ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: foreground,
            letterSpacing: letterSpacing,
          ),
        ),
      ),
    );
  }
}
