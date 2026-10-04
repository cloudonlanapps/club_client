import 'package:flutter/material.dart';

/// Centralized layout spacing constants for consistent UI.
abstract class LayoutConstants {
  static const double sectionSpacing = 16;
  static const double itemSpacing = 10;
  static const EdgeInsets contentPadding = EdgeInsets.all(16);
  static const SizedBox sectionGap = SizedBox(height: sectionSpacing);
  static const SizedBox itemGap = SizedBox(height: itemSpacing);
}
