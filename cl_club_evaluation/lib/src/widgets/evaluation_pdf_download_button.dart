import 'dart:async';
import 'dart:typed_data';

import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import '../utils/evaluation_pdf_opener.dart';

/// The download icon at the top right of a published review: downloads
/// the private member copy [media] with the session and hands its bytes to
/// [onOpenPdfBytes] (`openEvaluationPdf`); a failure shows a toast.
class EvaluationPdfDownloadButton extends ConsumerWidget {
  /// Downloads [media].
  const EvaluationPdfDownloadButton({
    required this.media,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The stored member copy.
  final MediaRef media;

  /// Shows the downloaded PDF, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    button: true,
    label: EvaluationViewStrings.downloadPdf,
    child: ShadIconButton.ghost(
      icon: const Icon(LucideIcons.download),
      onPressed: () =>
          unawaited(openEvaluationPdf(context, ref, media, onOpenPdfBytes)),
    ),
  );
}
