import 'dart:io';
import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

/// Prefix of the temporary directory a preview is written to.
const String pdfPreviewDirPrefix = 'club_pdf_preview_';

/// File name of a written preview.
const String pdfPreviewFileName = 'preview.pdf';

/// Writes [bytes] to a fresh temporary file and opens it with the
/// platform's PDF handler; returns whether the platform reported it opened.
Future<bool> openPdfBytes(Uint8List bytes) async {
  final dir = await Directory.systemTemp.createTemp(pdfPreviewDirPrefix);
  final file = File('${dir.path}${Platform.pathSeparator}$pdfPreviewFileName');
  await file.writeAsBytes(bytes, flush: true);
  return launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
}
