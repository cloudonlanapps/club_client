import 'package:flutter/material.dart';

/// Small capsule-shaped status pill at the top of a public event card.
///
/// Displays the registration / lifecycle state of an event (e.g.
/// "Registrations Open", "Registration Closed", "Past") or its stamp. The
/// caller supplies the resolved text and colours; this only handles shape.
class PublicEventStatusPill extends StatelessWidget {
  const PublicEventStatusPill({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  /// Background of an event's stamp pill.
  static const Color stampBackground = Color(0xFFFFF3BF);

  /// Text colour of an event's stamp pill.
  static const Color stampForeground = Color(0xFF7A5A00);

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
