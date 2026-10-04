import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop implementation (Linux/Windows/macOS).
///
/// webview_flutter has no desktop platform implementation, so instead of an
/// inline iframe we render a tappable card that opens the map in the system
/// browser. Importing nothing from webview_flutter keeps that plugin off the
/// desktop code path entirely.
Widget buildMapEmbed({
  required String embedUrl,
  required double height,
  String? linkUrl,
  String? fallbackTitle,
  String? openInMapsText,
}) {
  return MapEmbedDesktop(
    embedUrl: embedUrl,
    linkUrl: linkUrl,
    height: height,
    fallbackTitle: fallbackTitle,
    openInMapsText: openInMapsText,
  );
}

class MapEmbedDesktop extends StatelessWidget {
  const MapEmbedDesktop({
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

  Future<void> _openInBrowser() async {
    final mapsUrl = linkUrl ?? embedUrl;
    final uri = Uri.parse(mapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SizedBox(
      height: height,
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
                fallbackTitle ?? 'Open the location in Google Maps',
                style: TextStyle(color: theme.colorScheme.mutedForeground),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_new),
                label: Text(openInMapsText ?? 'Open in Google Maps'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
