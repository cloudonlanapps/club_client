import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clMediaBytesReaderProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/evaluation_view_strings.dart';
import 'evaluation_error_toast.dart';

/// Downloads the private PDF [media] — the stored member copy or evidence —
/// with the signed-in client (`clMediaBytesReaderProvider`), since its
/// plain URL is refused without the token, and hands its bytes to
/// [onBytes] while [context] is still mounted. A failure shows a friendly
/// toast and hands over nothing.
Future<void> openEvaluationPdf(
  BuildContext context,
  WidgetRef ref,
  MediaRef media,
  ValueChanged<Uint8List> onBytes,
) async {
  final read = ref.read(clMediaBytesReaderProvider);
  try {
    final bytes = await read(media);
    if (context.mounted) onBytes(bytes);
  } on Object catch (e) {
    showEvaluationErrorToast(
      context.mounted ? context : null,
      e,
      fallback: EvaluationViewStrings.pdfOpenFailed,
    );
  }
}
