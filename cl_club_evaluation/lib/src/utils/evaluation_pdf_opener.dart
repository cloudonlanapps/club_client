import 'package:cl_remote_store/cl_remote_store.dart'
    show clMediaBytesReaderProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/evaluation_view_strings.dart';
import 'evaluation_error_toast.dart';

/// Downloads the private PDF [media] — the stored member copy or evidence —
/// with the signed-in client (`clMediaBytesReaderProvider`), since its
/// plain URL is refused without the token, and hands its bytes to
/// [pdfAction] under the media's own file name while [context] is still
/// mounted (club_client#324). A failed download, or an action that could
/// not take the PDF, shows a friendly toast.
Future<void> openEvaluationPdf(
  BuildContext context,
  WidgetRef ref,
  MediaRef media,
  PdfAction pdfAction,
) async {
  final read = ref.read(clMediaBytesReaderProvider);
  try {
    final bytes = await read(media);
    if (context.mounted) await pdfAction.run(bytes, media.filename);
  } on Object catch (e) {
    showEvaluationErrorToast(
      context.mounted ? context : null,
      e,
      fallback: EvaluationViewStrings.pdfOpenFailed,
    );
  }
}
