import 'dart:async';

import 'package:cl_gallery_viewer/cl_gallery_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show openPdfDownload;

/// The auto-scrolling gallery strip of a public event: the phone or the
/// desktop gallery, with video playback and PDF download.
class PublicEventGalleryStrip extends StatelessWidget {
  const PublicEventGalleryStrip({
    required this.items,
    required this.isMobile,
    super.key,
  });

  /// How long each item shows before the strip moves on.
  static const Duration autoScrollInterval = Duration(seconds: 4);

  final List<GalleryItem> items;
  final bool isMobile;

  /// A player for a gallery video on this platform.
  static VideoPlayerInterface createPlayer() =>
      kIsWeb ? OverlayVideoPlayer() : NativeVideoPlayer();

  /// Straight to the API, shared with the member app's event gallery (#67).
  static void downloadPdf(String pdfUrl) => unawaited(openPdfDownload(pdfUrl));

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return GalleryMobile(
        items: items,
        playerFactory: createPlayer,
        onPdfDownload: downloadPdf,
        autoScrollInterval: autoScrollInterval,
      );
    }
    return GalleryDesktop(
      items: items,
      playerFactory: createPlayer,
      onPdfDownload: downloadPdf,
      autoScrollInterval: autoScrollInterval,
    );
  }
}
