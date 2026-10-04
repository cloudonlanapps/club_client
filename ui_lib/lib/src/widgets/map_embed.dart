import 'package:flutter/material.dart';

import 'map_embed_stub.dart'
    if (dart.library.html) 'map_embed_web.dart'
    if (dart.library.io) 'map_embed_native.dart'
    as platform;

/// A cross-platform widget that embeds a Google Maps iframe.
///
/// On web: Uses HtmlElementView with an iframe.
/// On mobile: Uses webview_flutter for an inline iframe.
/// On desktop: Renders a link card that opens the map in the system browser
/// (webview_flutter has no desktop platform implementation).
///
/// The [mapUri] can be either:
/// - Just the embed URL: "https://www.google.com/maps/embed?pb=..."
/// - Embed URL + link URL separated by |: "https://...embed...|https://maps.app.goo.gl/xxx"
class MapEmbed extends StatelessWidget {
  const MapEmbed({
    required this.mapUri,
    super.key,
    this.height = 400,
    this.fallbackTitle,
    this.openInMapsText,
  });

  final String mapUri;
  final double height;
  final String? fallbackTitle;
  final String? openInMapsText;

  /// Parse mapUri to extract embed URL and optional link URL.
  /// Format: "embedUrl" or "embedUrl|linkUrl"
  (String embedUrl, String? linkUrl) _parseMapUri() {
    final parts = mapUri.split('|');
    final embedUrl = parts[0].trim();
    final linkUrl = parts.length > 1 ? parts[1].trim() : null;
    return (embedUrl, linkUrl);
  }

  @override
  Widget build(BuildContext context) {
    final (embedUrl, linkUrl) = _parseMapUri();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: platform.buildMapEmbed(
        embedUrl: embedUrl,
        linkUrl: linkUrl,
        height: height,
        fallbackTitle: fallbackTitle,
        openInMapsText: openInMapsText,
      ),
    );
  }
}
