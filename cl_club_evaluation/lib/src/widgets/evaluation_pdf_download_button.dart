import 'dart:async';

import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../utils/evaluation_pdf_opener.dart';

/// The download icon at the top right of a published review: downloads
/// the private member copy [media] with the session and hands its bytes to
/// [pdfAction] (`openEvaluationPdf`); a failure shows a toast.
class EvaluationPdfDownloadButton extends ConsumerWidget {
  /// Downloads [media].
  const EvaluationPdfDownloadButton({
    required this.media,
    required this.pdfAction,
    super.key,
  });

  /// The stored member copy.
  final MediaRef media;

  /// What the downloaded PDF is handed to; its label and icon are the
  /// button's.
  final PdfAction pdfAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Semantics(
    button: true,
    label: pdfAction.label,
    child: ShadIconButton.ghost(
      icon: Icon(pdfAction.icon),
      onPressed: () =>
          unawaited(openEvaluationPdf(context, ref, media, pdfAction)),
    ),
  );
}
