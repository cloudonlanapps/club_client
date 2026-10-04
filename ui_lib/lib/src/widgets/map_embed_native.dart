import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import 'map_embed_desktop.dart' as desktop;
import 'map_embed_mobile.dart' as mobile;

/// Native entry point selected via `if (dart.library.io)`.
///
/// `dart.library.io` is true for mobile *and* desktop, and Dart conditional
/// imports cannot distinguish the two, so we dispatch at runtime:
/// - Android/iOS use webview_flutter for an inline iframe.
/// - Desktop (Linux/Windows/macOS) falls back to a link card, because
///   webview_flutter ships no desktop platform implementation.
Widget buildMapEmbed({
  required String embedUrl,
  required double height,
  String? linkUrl,
  String? fallbackTitle,
  String? openInMapsText,
}) {
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.buildMapEmbed(
      embedUrl: embedUrl,
      height: height,
      linkUrl: linkUrl,
      fallbackTitle: fallbackTitle,
      openInMapsText: openInMapsText,
    );
  }
  return desktop.buildMapEmbed(
    embedUrl: embedUrl,
    height: height,
    linkUrl: linkUrl,
    fallbackTitle: fallbackTitle,
    openInMapsText: openInMapsText,
  );
}
