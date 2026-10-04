import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Custom color keys for the film roll aesthetic and calendar highlights.
/// These are used in ShadColorScheme.custom map.
abstract class CustomColorKeys {
  static const filmOverlay = 'filmOverlay';
  static const filmOverlayText = 'filmOverlayText';
  static const filmSprocketBackground = 'filmSprocketBackground';
  static const filmSprocketHole = 'filmSprocketHole';
  static const specialEventHighlight = 'specialEventHighlight';
}

/// Extension to access custom film roll colors from the theme.
///
/// Host apps must include [lightCustomColors] or [darkCustomColors] in their
/// `ShadColorScheme.copyWith(custom: ...)` for these getters to work.
extension FilmRollColorsExtension on ShadColorScheme {
  /// Overlay color for vignette and gradient effects on images.
  Color get filmOverlay => custom[CustomColorKeys.filmOverlay]!;

  /// Text color for labels on dark gradient overlays.
  Color get filmOverlayText => custom[CustomColorKeys.filmOverlayText]!;

  /// Sprocket strip background (film edge aesthetic).
  Color get filmSprocketBackground =>
      custom[CustomColorKeys.filmSprocketBackground]!;

  /// Sprocket hole color (film aesthetic).
  Color get filmSprocketHole => custom[CustomColorKeys.filmSprocketHole]!;

  /// Highlight color for days with special events (one-off, camp).
  Color get specialEventHighlight =>
      custom[CustomColorKeys.specialEventHighlight]!;
}

/// Custom colors for light theme - film roll aesthetic.
const Map<String, Color> lightCustomColors = {
  CustomColorKeys.filmOverlay: Colors.black,
  CustomColorKeys.filmOverlayText: Colors.white,
  CustomColorKeys.filmSprocketBackground: Color(0xDD000000),
  CustomColorKeys.filmSprocketHole: Color(0x3DFFFFFF),
  CustomColorKeys.specialEventHighlight: Color(0xFFFEF3C7),
};

/// Custom colors for dark theme - film roll aesthetic.
/// Slightly adjusted for better visibility on dark backgrounds.
const Map<String, Color> darkCustomColors = {
  CustomColorKeys.filmOverlay: Colors.black,
  CustomColorKeys.filmOverlayText: Colors.white,
  CustomColorKeys.filmSprocketBackground: Color(0xCC000000),
  CustomColorKeys.filmSprocketHole: Color(0x4DFFFFFF),
  CustomColorKeys.specialEventHighlight: Color(0xFF92400E),
};
