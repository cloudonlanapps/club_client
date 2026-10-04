import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mobile implementation using webview_flutter (Android/iOS only).
///
/// webview_flutter ships no desktop platform implementation, so desktop
/// targets are routed to `map_embed_desktop.dart` by the dispatcher in
/// `map_embed_native.dart` and never reach this file.
Widget buildMapEmbed({
  required String embedUrl,
  required double height,
  String? linkUrl,
  String? fallbackTitle,
  String? openInMapsText,
}) {
  return MapEmbedMobile(
    embedUrl: embedUrl,
    linkUrl: linkUrl,
    height: height,
    fallbackTitle: fallbackTitle,
    openInMapsText: openInMapsText,
  );
}

class MapEmbedMobile extends StatefulWidget {
  const MapEmbedMobile({
    required this.embedUrl,
    required this.height,
    this.linkUrl,
    this.fallbackTitle,
    this.openInMapsText,
    super.key,
  });

  final String embedUrl;
  final String? linkUrl;
  final double height;
  final String? fallbackTitle;
  final String? openInMapsText;

  @override
  State<MapEmbedMobile> createState() => MapEmbedMobileState();
}

class MapEmbedMobileState extends State<MapEmbedMobile> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Google Maps Embed API requires being loaded inside an iframe.
    // We create an HTML page that wraps the embed URL in an iframe.
    final html =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <iframe
    src="${widget.embedUrl}"
    allowfullscreen
    loading="lazy"
    referrerpolicy="origin">
  </iframe>
</body>
</html>
''';

    _controller = WebViewController();
    unawaited(
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted),
    );
    unawaited(
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      ),
    );
    unawaited(_controller.loadHtmlString(html));
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildFallback(context);
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SizedBox(
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 48,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                widget.fallbackTitle ?? 'Map could not be loaded',
                style: TextStyle(color: theme.colorScheme.mutedForeground),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_new),
                label: Text(widget.openInMapsText ?? 'Open in Google Maps'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final mapsUrl = widget.linkUrl ?? widget.embedUrl;
    final uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
