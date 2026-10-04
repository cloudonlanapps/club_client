import 'dart:async';
import 'dart:typed_data';

import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show
        GalleryDesktop,
        GalleryItem,
        GalleryMobile,
        NativeVideoPlayer,
        OverlayVideoPlayer,
        VideoPlayerInterface;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show mediaRefDownloadUrlProvider, mediaRefPosterUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaLink, MediaRef;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

import '../constants/evaluation_view_sizes.dart';
import '../utils/evaluation_gallery_items.dart';
import '../utils/evaluation_pdf_opener.dart';

/// An answer's evidence in the gallery viewer (`cl_gallery_viewer`):
/// images, videos and PDFs. Evidence is private, so every request carries
/// the session's headers (`imageAuthHeadersProvider`), and a PDF is
/// downloaded with the token and handed to [onOpenPdfBytes] as bytes.
class EvaluationEvidenceGallery extends ConsumerWidget {
  /// Shows [links].
  const EvaluationEvidenceGallery({
    required this.links,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The evidence files.
  final List<MediaLink> links;

  /// Shows a downloaded PDF, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// The variant a gallery shows.
  static const String originalVariant = 'original';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byUrl = <String, MediaRef>{
      for (final link in links)
        ref.watch(
          mediaRefDownloadUrlProvider((
            media: link.media,
            variant: originalVariant,
          )),
        ): link.media,
    };
    final items = <GalleryItem>[
      for (final MapEntry(key: url, value: media) in byUrl.entries)
        EvaluationGalleryItems.of(
          media,
          url,
          ref.watch(mediaRefPosterUrlProvider(media)),
        ),
    ];
    final headers = ref.watch(imageAuthHeadersProvider).valueOrNull;
    void openPdf(String url) {
      final media = byUrl[url];
      if (media == null) return;
      unawaited(openEvaluationPdf(context, ref, media, onOpenPdfBytes));
    }

    return isMobileWidth(context)
        ? GalleryMobile(
            items: items,
            playerFactory: createPlayer,
            onPdfDownload: openPdf,
            httpHeaders: headers ?? const {},
            height: EvaluationViewSizes.galleryHeight,
          )
        : GalleryDesktop(
            items: items,
            playerFactory: createPlayer,
            onPdfDownload: openPdf,
            httpHeaders: headers ?? const {},
            height: EvaluationViewSizes.galleryHeight,
          );
  }

  /// A video player: the overlay player on the web, else the native one.
  static VideoPlayerInterface createPlayer() =>
      kIsWeb ? OverlayVideoPlayer() : NativeVideoPlayer();
}
