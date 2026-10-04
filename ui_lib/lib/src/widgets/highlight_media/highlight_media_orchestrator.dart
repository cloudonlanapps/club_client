import 'package:cl_gallery_viewer/cl_gallery_viewer.dart';
import 'package:flutter/material.dart';

/// Platform-aware media orchestrator that delegates rendering to
/// [HighlightMedia] from cl_gallery_viewer.
///
/// Handles platform/browser detection and decides:
/// - Whether to show video or webp preview
/// - Which [VideoPlayerFactory] to use
/// - Which overlay button to display (mute vs popup)
///
/// Build logic:
/// - Image/webp URL → displays directly via [HighlightMedia]
/// - Video URL on Native or Web/Blink → inline video with [AudioControllerAudioMute]
/// - Video URL on Web/non-Blink → webp preview with [PopOverVideoPlayer]
VideoPlayerInterface _createMediaKitPlayer() => MediaKitVideoPlayer();
VideoPlayerInterface _createOverlayPlayer() => OverlayVideoPlayer();

class HighlightMediaOrchestrator extends StatelessWidget {
  const HighlightMediaOrchestrator({
    required this.uri,
    this.fit = BoxFit.cover,
    this.showOverlayButton = false,
    this.overlayButtonPosition = Alignment.topRight,
    this.borderRadius = BorderRadius.zero,
    this.isVideo,
    this.previewUri,
    super.key,
  });

  final String uri;
  final BoxFit fit;
  final bool showOverlayButton;
  final Alignment overlayButtonPosition;
  final BorderRadius borderRadius;

  /// Whether [uri] is a video, when the caller knows and the URL does not say.
  ///
  /// The rule is normally the file extension, which works for a path and not
  /// for a media download URL: those address media by uuid and end in
  /// `/download`. A caller that has asked the server what the media is passes
  /// the answer here.
  final bool? isVideo;

  /// What to show where the video cannot play inline, when [uri] has no
  /// derivable preview.
  ///
  /// The animated-webp preview is normally the video's own URL with the
  /// extension swapped, which again needs a URL with an extension. Null keeps
  /// that derivation.
  final String? previewUri;

  @override
  Widget build(BuildContext context) {
    if (!(isVideo ?? VideoUrlUtils.isVideoUrl(uri))) {
      return buildImageMedia();
    }

    return buildVideoMedia();
  }

  Widget buildImageMedia() {
    return ClipRRect(
      borderRadius: borderRadius,
      child: HighlightMedia(url: uri, fit: fit),
    );
  }

  Widget buildVideoMedia() {
    // On native platforms and Blink browsers: play video inline
    // On web non-Blink browsers: show animated webp preview
    final useInlineVideo = isBlinkBrowser;

    // Off the inline path, show the caller's preview. Deriving one — a
    // sibling `..._poster.webp` — is only right for a static file tree; the
    // server keeps a preview at the same address under `?variant=`, and the
    // derived path 404s (club_server#424).
    final mediaUrl = useInlineVideo
        ? uri
        : (previewUri ?? VideoUrlUtils.getWebpUrl(uri));
    // Use top-level function references to keep closures stable across
    // rebuilds. Avoids unnecessary didUpdateWidget triggers in HighlightMedia.
    final factory = useInlineVideo ? _createMediaKitPlayer : null;

    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // `isVideo` is not passed down, and no longer needs to be:
            // HighlightMedia sniffs the URL and the URL now ends in a real
            // file extension (club_server#424), so both layers reach the same
            // answer. The parameter here stays for callers that know better
            // than any URL — a cover the server has typed, say.
            HighlightMedia(url: mediaUrl, playerFactory: factory, fit: fit),
            if (showOverlayButton)
              buildOverlayButton(useInlineVideo: useInlineVideo),
          ],
        ),
      ),
    );
  }

  Widget buildOverlayButton({required bool useInlineVideo}) {
    // Use Align without Positioned.fill to avoid consuming taps
    // on the entire area. Only the button itself should be a hit target.
    return Align(
      alignment: overlayButtonPosition,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: useInlineVideo
            ? const AudioControllerAudioMute()
            : PopOverVideoPlayer(
                videoUrl: uri,
                playerFactory: _createOverlayPlayer,
              ),
      ),
    );
  }
}
