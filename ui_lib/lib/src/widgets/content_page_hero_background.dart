import 'package:flutter/material.dart';

import 'credentialed_network_image.dart' show CredentialedNetworkImage;
import 'highlight_media/highlight_media_orchestrator.dart';

/// The picture behind a `ContentPageHeroSection`: the page's own image when
/// it has one, the [fallbackImageUri] otherwise.
///
/// The page image loads with [httpHeaders] when they are given (authenticated
/// media); the fallback is public — a bundled asset or site media — and
/// always goes through [HighlightMediaOrchestrator]. With neither URI it
/// renders nothing.
class ContentPageHeroBackground extends StatelessWidget {
  const ContentPageHeroBackground({
    super.key,
    this.imageUri,
    this.fallbackImageUri,
    this.httpHeaders,
  });

  /// The page's own image or video.
  final String? imageUri;

  /// Shown when [imageUri] is null.
  final String? fallbackImageUri;

  /// Auth headers for [imageUri].
  final Map<String, String>? httpHeaders;

  @override
  Widget build(BuildContext context) {
    final image = imageUri;
    final headers = httpHeaders;
    if (image != null && headers != null) {
      return CredentialedNetworkImage(
        imageUrl: image,
        httpHeaders: headers,
        fit: BoxFit.cover,
        errorBuilder: (_) => const SizedBox.shrink(),
      );
    }
    final uri = image ?? fallbackImageUri;
    if (uri == null) return const SizedBox.shrink();
    return HighlightMediaOrchestrator(uri: uri);
  }
}
