import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationMediaProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EvaluationStaffView, EvaluationStatus;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'evaluation_pdf_download_button.dart';
import 'evaluation_top_bar.dart';

/// The top of the owner's editor: **Back**, and — once [evaluation] is
/// published and its member copy stored — the download icon at the top
/// right.
class EvaluationEditTopBar extends ConsumerWidget {
  /// The top bar of [evaluation].
  const EvaluationEditTopBar({
    required this.evaluation,
    required this.onBack,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The evaluation, as its owner reads it.
  final EvaluationStaffView evaluation;

  /// Leaves the editor, without asking.
  final VoidCallback onBack;

  /// Shows the downloaded member copy, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = evaluation;
    final copy = e.status == EvaluationStatus.published
        ? ref.watch(clEvaluationMediaProvider(e.id)).valueOrNull?.memberCopy
        : null;
    return EvaluationTopBar(
      onBack: onBack,
      trailing: copy == null
          ? null
          : EvaluationPdfDownloadButton(
              media: copy.media,
              onOpenPdfBytes: onOpenPdfBytes,
            ),
    );
  }
}
