import 'package:cl_gallery_viewer/cl_gallery_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive gallery display that renders mobile or desktop gallery.
///
/// Uses [GalleryMobile] (PageView) on mobile and [GalleryDesktop]
/// (horizontal scroll) on desktop with auto-scroll enabled.
class GalleryDisplay extends StatelessWidget {
  const GalleryDisplay({
    required this.items,
    required this.isMobile,
    this.onPdfDownload,
    super.key,
  });

  final List<GalleryItem> items;
  final bool isMobile;
  final ValueChanged<String>? onPdfDownload;

  @override
  Widget build(BuildContext context) {
    VideoPlayerInterface createPlayer() =>
        kIsWeb ? OverlayVideoPlayer() : NativeVideoPlayer();

    if (isMobile) {
      return GalleryMobile(
        items: items,
        playerFactory: createPlayer,
        onPdfDownload: onPdfDownload,
      );
    }

    return GalleryDesktop(
      items: items,
      playerFactory: createPlayer,
      onPdfDownload: onPdfDownload,
    );
  }
}
