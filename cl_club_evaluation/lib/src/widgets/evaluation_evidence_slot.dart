import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationMediaProvider, clEvaluationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaLink;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../utils/evaluation_error_toast.dart';
import 'evaluation_evidence_gallery.dart';
import 'evaluation_evidence_tile.dart';
import 'evaluation_evidence_uploader.dart';

/// The evidence slot of one question in the owner's editor. Each file
/// shows once: on a draft, as its own card with its remove action, then
/// **Attach evidence**; otherwise in the gallery viewer. Evidence is the
/// member's file, downloadable by the member and staff only, so a PDF is
/// downloaded with the session and handed to [onOpenPdfBytes] as bytes.
class EvaluationEvidenceSlot extends ConsumerWidget {
  /// The evidence on [itemId] of [evaluationId].
  const EvaluationEvidenceSlot({
    required this.evaluationId,
    required this.itemId,
    required this.editable,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The evaluation.
  final int evaluationId;

  /// The question.
  final int itemId;

  /// Whether evidence may change (a draft).
  final bool editable;

  /// Shows a downloaded evidence PDF, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  /// Detaches [link] from the item.
  Future<void> remove(
    BuildContext context,
    WidgetRef ref,
    MediaLink link,
  ) async {
    try {
      await ref
          .read(clEvaluationsMasterProvider.notifier)
          .detachEvidence(evaluationId, itemId, link.mediaUuid);
    } on Object catch (e) {
      showEvaluationErrorToast(
        context.mounted ? context : null,
        e,
        fallback: EvaluationViewStrings.evidenceRemoveFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(clEvaluationMediaProvider(evaluationId));
    final links = media.valueOrNull?.evidenceFor(itemId) ?? const [];
    if (!editable) {
      return links.isEmpty
          ? const SizedBox.shrink()
          : EvaluationEvidenceGallery(
              links: links,
              onOpenPdfBytes: onOpenPdfBytes,
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EvaluationViewSizes.smallGap,
      children: [
        if (links.isNotEmpty)
          Wrap(
            spacing: EvaluationViewSizes.smallGap,
            runSpacing: EvaluationViewSizes.smallGap,
            children: [
              for (final link in links)
                EvaluationEvidenceTile(
                  key: ValueKey(link.mediaUuid),
                  link: link,
                  onRemove: () => remove(context, ref, link),
                  onOpenPdfBytes: onOpenPdfBytes,
                ),
            ],
          ),
        EvaluationEvidenceUploader(evaluationId: evaluationId, itemId: itemId),
      ],
    );
  }
}
