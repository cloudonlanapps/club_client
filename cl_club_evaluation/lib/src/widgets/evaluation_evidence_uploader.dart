import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show FilePickerAdapter, MediaKind, defaultFilePicker;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationsMasterProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import '../utils/evaluation_error_toast.dart';

/// **Attach evidence** to item [itemId] of draft [evaluationId]: picks
/// images, videos and PDFs, and uploads each through the evaluations
/// master in one call that stores it as the member's file — the member and
/// staff may download it, nobody else — and links it under the item.
class EvaluationEvidenceUploader extends ConsumerStatefulWidget {
  /// Attaches to [itemId] of [evaluationId]; [pickFiles] picks the files.
  const EvaluationEvidenceUploader({
    required this.evaluationId,
    required this.itemId,
    this.pickFiles = defaultFilePicker,
    super.key,
  });

  /// The draft.
  final int evaluationId;

  /// The question the evidence justifies.
  final int itemId;

  /// Picks the files to upload: the platform picker unless a test gives
  /// another.
  final FilePickerAdapter pickFiles;

  /// The kinds evidence may be.
  static const Set<MediaKind> evidenceKinds = {
    MediaKind.image,
    MediaKind.video,
    MediaKind.pdf,
  };

  @override
  ConsumerState<EvaluationEvidenceUploader> createState() =>
      EvaluationEvidenceUploaderState();
}

/// State of [EvaluationEvidenceUploader]: whether an upload is running.
class EvaluationEvidenceUploaderState
    extends ConsumerState<EvaluationEvidenceUploader> {
  /// Whether files are being uploaded.
  bool uploading = false;

  /// Picks files and uploads each in turn; a refused file is reported and
  /// the rest still go.
  Future<void> attach() async {
    final picked = await widget.pickFiles(
      allowMultiple: true,
      allowedKinds: EvaluationEvidenceUploader.evidenceKinds,
    );
    if (picked.isEmpty || !mounted) return;
    final notifier = ref.read(clEvaluationsMasterProvider.notifier);
    setState(() => uploading = true);
    for (final file in picked) {
      try {
        await notifier.uploadEvidence(
          widget.evaluationId,
          widget.itemId,
          bytes: file.bytes,
          filename: file.filename,
          contentType: file.mimeType,
        );
      } on Object catch (e) {
        showEvaluationErrorToast(
          mounted ? context : null,
          e,
          fallback: EvaluationViewStrings.evidenceFailed,
          title: file.filename,
        );
      }
    }
    if (mounted) setState(() => uploading = false);
  }

  @override
  Widget build(BuildContext context) => ShadButton.outline(
    size: ShadButtonSize.sm,
    onPressed: uploading ? null : attach,
    leading: const Icon(LucideIcons.paperclip),
    child: const Text(
      EvaluationViewStrings.attachEvidence,
    ),
  );
}
