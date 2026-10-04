import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart' show HighlightMediaOrchestrator;

/// Widget that displays background media (image or video).
///
/// Delegates to [HighlightMediaOrchestrator] which handles
/// platform/browser detection and video vs webp selection.
///
/// Usage:
/// ```dart
/// HeroVideoBackground(
///   videoUri: null,
///   defaultBackground: 'https://example.com/media.mp4',
/// )
/// ```
class HeroVideoBackground extends StatelessWidget {
  const HeroVideoBackground({
    required this.videoUri,
    required this.defaultBackground,
    super.key,
    this.isVideo,
    this.previewUri,
    this.fit = BoxFit.cover,
    this.showOverlayButton = true,
    this.overlayButtonPosition = Alignment.bottomRight,
  });

  /// Current video URI (can be null to use defaultBackground)
  final String? videoUri;

  /// Fallback background (can be image or video URL)
  final String defaultBackground;

  /// Whether the media is a video, from whoever knows — the server says so
  /// for its own media, and that beats reading the URL.
  final bool? isVideo;

  /// What to show where a video cannot play inline.
  ///
  /// The server's own still when it has one. Never derived from the media
  /// URL: a preview lives at the same address under `?variant=poster`, and
  /// the sibling path a URL implies 404s (club_server#424).
  final String? previewUri;

  /// How to fit the media in its container
  final BoxFit fit;

  /// Whether to show overlay button (mute for video on Chrome, popup on
  /// Safari/Firefox)
  final bool showOverlayButton;

  /// Position of the overlay button
  final Alignment overlayButtonPosition;

  @override
  Widget build(BuildContext context) {
    final uri = videoUri ?? defaultBackground;

    // AnimatedSwitcher for crossfade effect when URI changes
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: SizedBox.expand(
        key: ValueKey(uri),
        child: HighlightMediaOrchestrator(
          uri: uri,
          fit: fit,
          showOverlayButton: showOverlayButton,
          overlayButtonPosition: overlayButtonPosition,
          isVideo: isVideo,
          previewUri: previewUri,
        ),
      ),
    );
  }
}
