import 'dart:async';
import 'dart:typed_data';

import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show GalleryPdfCard, GalleryVideoPlayer;
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show mediaRefDownloadUrlProvider, mediaRefPosterUrlProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaLink;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../utils/evaluation_pdf_opener.dart';
import 'evaluation_evidence_gallery.dart';

/// One evidence file in the owner's editor, shown once: the gallery's own
/// card for it — an image, a video with its poster, a PDF with its preview
/// — with its remove action in the corner. Evidence is private, so every
/// request carries the session's headers and a PDF is downloaded with the
/// session and handed to [onOpenPdfBytes] as bytes.
class EvaluationEvidenceTile extends ConsumerWidget {
  /// Shows [link], removed by [onRemove].
  const EvaluationEvidenceTile({
    required this.link,
    required this.onRemove,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The evidence file.
  final MediaLink link;

  /// Removes the file from the answer.
  final VoidCallback onRemove;

  /// Shows a downloaded PDF, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = link.media;
    final url = ref.watch(
      mediaRefDownloadUrlProvider((
        media: media,
        variant: EvaluationEvidenceGallery.originalVariant,
      )),
    );
    final poster = ref.watch(mediaRefPosterUrlProvider(media));
    final headers = ref.watch(imageAuthHeadersProvider).valueOrNull ?? const {};
    final colors = ShadTheme.of(context).colorScheme;
    final Widget card;
    if (media.isPdf) {
      card = GalleryPdfCard(
        pdfUrl: url,
        previewUrl: poster,
        httpHeaders: headers,
        onDownload: () => unawaited(
          openEvaluationPdf(context, ref, media, onOpenPdfBytes),
        ),
      );
    } else if (media.isVideo) {
      card = GalleryVideoPlayer(
        videoUrl: url,
        videoId: media.uuid,
        posterUrl: poster,
        isActiveVideo: true,
        onPlayStateChanged: (_, {required isPlaying}) {},
        playerFactory: EvaluationEvidenceGallery.createPlayer,
        httpHeaders: headers,
      );
    } else {
      card = Image.network(
        url,
        headers: headers.isEmpty ? null : headers,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: colors.muted,
          child: Icon(LucideIcons.imageOff, color: colors.mutedForeground),
        ),
      );
    }
    return SizedBox(
      width: EvaluationViewSizes.evidenceTileWidth,
      height: EvaluationViewSizes.evidenceTileHeight,
      child: ClipRRect(
        borderRadius: ShadTheme.of(context).radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            card,
            PositionedDirectional(
              top: EvaluationViewSizes.evidenceTileInset,
              end: EvaluationViewSizes.evidenceTileInset,
              child: Semantics(
                label: EvaluationViewStrings.removeEvidence,
                button: true,
                excludeSemantics: true,
                child: ShadIconButton.secondary(
                  icon: const Icon(LucideIcons.x),
                  onPressed: onRemove,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
