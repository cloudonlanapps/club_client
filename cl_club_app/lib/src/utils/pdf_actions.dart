import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import 'pdf_platform.dart' as pdf_platform;
import 'share_outcome.dart';

/// Hands a PDF held in memory to the platform as a file name.
typedef PdfBytesHandler =
    Future<void> Function(Uint8List bytes, String fileName);

/// Shows a share sheet for a PDF held in memory.
typedef PdfBytesSharer =
    Future<ShareOutcome> Function(Uint8List bytes, String fileName);

/// The one thing a PDF button does on a platform (club_client#324).
enum PdfActionKind {
  /// The share sheet: the app on Android or iOS, or a phone's browser that
  /// can share files.
  share,

  /// A download to the browser's folder: a desktop browser, or a phone's
  /// browser that cannot share files.
  download,

  /// The platform's PDF viewer: the desktop app (Linux), as before.
  open,
}

/// The button's words for each action.
abstract final class PdfActionStrings {
  /// Shares the PDF.
  static const String share = 'Share';

  /// Downloads (or opens) the PDF.
  static const String download = 'Download';
}

/// The action a PDF button takes in a browser ([web]) or app on
/// [platform], where the browser can share files or not ([canShareFiles]).
/// A phone is Android or iOS, as `FormAutofocus.allowedOn` tells a phone's
/// browser.
PdfActionKind pdfActionKindFor({
  required bool web,
  required TargetPlatform platform,
  required bool canShareFiles,
}) {
  final phone = switch (platform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
  if (!web) return phone ? PdfActionKind.share : PdfActionKind.open;
  return phone && canShareFiles ? PdfActionKind.share : PdfActionKind.download;
}

/// Shares [bytes] as [fileName] with [share]; when the platform refuses
/// the sheet (a browser whose tap has expired), downloads them with
/// [download] instead. A sheet the person closed does nothing more.
Future<void> shareOrDownload(
  Uint8List bytes,
  String fileName, {
  required PdfBytesSharer share,
  required PdfBytesHandler download,
}) async {
  final outcome = await share(bytes, fileName);
  if (outcome == ShareOutcome.refused) await download(bytes, fileName);
}

/// The [PdfAction] of [kind], doing its work with [share], [download] and
/// [open].
PdfAction pdfActionOf(
  PdfActionKind kind, {
  required PdfBytesSharer share,
  required PdfBytesHandler download,
  required PdfBytesHandler open,
}) => switch (kind) {
  PdfActionKind.share => PdfAction(
    label: PdfActionStrings.share,
    icon: LucideIcons.share2,
    run: (bytes, fileName) =>
        shareOrDownload(bytes, fileName, share: share, download: download),
  ),
  PdfActionKind.download => PdfAction(
    label: PdfActionStrings.download,
    icon: LucideIcons.download,
    run: download,
  ),
  PdfActionKind.open => PdfAction(
    label: PdfActionStrings.download,
    icon: LucideIcons.download,
    run: open,
  ),
};

/// What [appPdfAction] hands a PDF's bytes to in place of the platform,
/// when set: the UI integration suite's stand-in, so a run on the desktop
/// never launches the system's PDF viewer and can check the bytes the
/// button fetched (club_client#341). Null in the app, which then does what
/// the platform's action does.
@visibleForTesting
PdfBytesHandler? debugPdfBytesHandler;

/// [action], handing its bytes to [debugPdfBytesHandler] while one is set.
PdfAction withDebugPdfBytesHandler(PdfAction action) => PdfAction(
  label: action.label,
  icon: action.icon,
  run: (bytes, fileName) =>
      (debugPdfBytesHandler ?? action.run)(bytes, fileName),
);

/// The PDF action of the platform the app runs on, which every PDF button
/// of the app's packages is given; worked out once, on first use.
final PdfAction appPdfAction = withDebugPdfBytesHandler(
  pdfActionOf(
    pdfActionKindFor(
      web: kIsWeb,
      platform: defaultTargetPlatform,
      canShareFiles: kIsWeb && pdf_platform.canShareFiles(),
    ),
    share: pdf_platform.sharePdfBytes,
    download: pdf_platform.downloadPdfBytes,
    open: pdf_platform.openPdfBytes,
  ),
);
