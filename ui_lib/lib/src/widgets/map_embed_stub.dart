import 'package:flutter/widgets.dart';

/// Stub implementation - should never be called directly.
/// Uses conditional imports to select the correct platform implementation.
Widget buildMapEmbed({
  required String embedUrl,
  required double height,
  String? linkUrl,
  String? fallbackTitle,
  String? openInMapsText,
}) {
  throw UnsupportedError('Cannot create MapEmbed without dart:html or webview');
}
