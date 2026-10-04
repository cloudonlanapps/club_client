import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clMemberEvaluationMediaProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationMemberView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show EvaluationReadBody;

import '../models/evaluation_answer_adapter.dart';
import '../models/evaluation_layout_adapter.dart';
import 'evaluation_evidence_gallery.dart';
import 'evaluation_page.dart';
import 'evaluation_pdf_download_button.dart';
import 'evaluation_period_section.dart';
import 'evaluation_top_bar.dart';

/// A published [review]: its title as the page title, with the download
/// icon for the stored member copy at the top right; the Review Period
/// section (left out when there is neither an event nor a period); and its
/// sections and answers with their evidence, the closing Q & As last in one
/// untitled card. Both the copy and the evidence are private, so a PDF is
/// downloaded with the session and handed to [onOpenPdfBytes] as bytes.
class EvaluationReadContent extends ConsumerWidget {
  /// Shows [review].
  const EvaluationReadContent({
    required this.review,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The review, as the member reads it.
  final EvaluationMemberView review;

  /// Shows a downloaded PDF, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (username: review.createdFor, evaluationId: review.id);
    final media = ref.watch(clMemberEvaluationMediaProvider(key)).valueOrNull;
    final copy = media?.memberCopy;
    return EvaluationPage(
      children: [
        EvaluationTopBar(
          title: review.template.name,
          trailing: copy == null
              ? null
              : EvaluationPdfDownloadButton(
                  media: copy.media,
                  onOpenPdfBytes: onOpenPdfBytes,
                ),
        ),
        EvaluationPeriodSection(
          member: review.createdFor,
          eventId: review.eventId,
          startUtc: review.periodStartUtc,
          endUtc: review.periodEndUtc,
        ),
        EvaluationReadBody(
          layout: EvaluationLayoutAdapter.fromTemplate(
            review.template.layout,
            review.template.items,
          ),
          answers: EvaluationAnswerAdapter.toValues(review.answers),
          evidenceBuilder: (itemId) {
            final links = media?.evidenceFor(itemId) ?? const [];
            return links.isEmpty
                ? const SizedBox.shrink()
                : EvaluationEvidenceGallery(
                    links: links,
                    onOpenPdfBytes: onOpenPdfBytes,
                  );
          },
        ),
      ],
    );
  }
}
