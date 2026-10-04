import 'package:flutter/painting.dart';

/// Hex digits in an opaque `RRGGBB` colour.
const int kRgbHexLength = 6;

/// Hex digits in an `AARRGGBB` colour.
const int kArgbHexLength = 8;

/// The alpha prefix an `RRGGBB` colour is read with.
const String kOpaqueAlphaHex = 'FF';

/// The optional prefix of a hex colour.
const String kHexColorPrefix = '#';

/// Radix of a hex colour string.
const int kHexRadix = 16;

/// Parses `#RRGGBB`, `RRGGBB`, `#AARRGGBB` or `AARRGGBB` (alpha defaults to
/// opaque). Null for null, empty or malformed input, so the caller falls back
/// to a default.
Color? parseHexColor(String? raw) {
  if (raw == null) return null;
  var hex = raw.trim();
  if (hex.startsWith(kHexColorPrefix)) hex = hex.substring(1);
  if (hex.length == kRgbHexLength) hex = '$kOpaqueAlphaHex$hex';
  if (hex.length != kArgbHexLength) return null;
  final value = int.tryParse(hex, radix: kHexRadix);
  if (value == null) return null;
  return Color(value);
}

/// Formats [color] as `#AARRGGBB`, which [parseHexColor] reads back.
String formatHexColor(Color color) {
  final digits = color
      .toARGB32()
      .toRadixString(kHexRadix)
      .padLeft(kArgbHexLength, '0')
      .toUpperCase();
  return '$kHexColorPrefix$digits';
}
