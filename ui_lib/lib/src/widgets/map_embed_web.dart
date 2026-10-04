// Web-only implementation needs dart:html for the iframe element.
// ignore_for_file: avoid_web_libraries_in_flutter

// dart:html is deprecated in favour of package:web, but switching the iframe
// implementation is out of scope for this file.
import 'dart:html' as html; // ignore: deprecated_member_use
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Set of registered view types to prevent duplicate registration.
final Set<String> registeredViewTypes = {};

/// Check if running on Chrome or Firefox (browsers where iframe works)
bool get isChromiumOrFirefox {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('chrome') || userAgent.contains('firefox');
}

/// Web implementation using HtmlElementView with iframe.
/// Falls back to a link on Safari due to iframe compatibility issues.
Widget buildMapEmbed({
  required String embedUrl,
  required double height,
  String? linkUrl,
  String? fallbackTitle,
  String? openInMapsText,
}) {
  // Use iframe only on Chrome/Firefox where it works reliably
  if (isChromiumOrFirefox) {
    return MapEmbedWeb(embedUrl: embedUrl, height: height);
  }
  // Safari and other browsers get the reliable fallback
  return MapEmbedFallback(
    linkUrl: linkUrl ?? embedUrl,
    height: height,
    title: fallbackTitle,
    buttonText: openInMapsText,
  );
}

/// Fallback widget that shows a button to open Google Maps
class MapEmbedFallback extends StatelessWidget {
  const MapEmbedFallback({
    required this.linkUrl,
    required this.height,
    this.title,
    this.buttonText,
    super.key,
  });

  final String linkUrl;
  final double height;
  final String? title;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 48,
              color: theme.colorScheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'View Location',
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ShadButton(
              onPressed: _openInMaps,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.externalLink, size: 16),
                  const SizedBox(width: 8),
                  Text(buttonText ?? 'Open in Google Maps'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps() async {
    final uri = Uri.parse(linkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class MapEmbedWeb extends StatefulWidget {
  const MapEmbedWeb({
    required this.embedUrl,
    required this.height,
    super.key,
  });

  final String embedUrl;
  final double height;

  @override
  State<MapEmbedWeb> createState() => MapEmbedWebState();
}

class MapEmbedWebState extends State<MapEmbedWeb> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'map-embed-${widget.embedUrl.hashCode}';
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (registeredViewTypes.contains(_viewType)) return;
    registeredViewTypes.add(_viewType);

    final embedUrl = widget.embedUrl;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = embedUrl
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..setAttribute('allowfullscreen', '')
          ..setAttribute('loading', 'lazy')
          ..setAttribute('referrerpolicy', 'no-referrer-when-downgrade')
          ..setAttribute('allow', 'fullscreen');
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
