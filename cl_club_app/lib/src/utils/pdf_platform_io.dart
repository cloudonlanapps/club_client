import 'dart:io';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'save_file_bytes_io.dart';
import 'share_outcome.dart';

/// Prefix of the temporary directory a PDF is written to for the viewer.
const String pdfOpenDirPrefix = 'club_pdf_';

/// Whether the share sheet can take a file: the app's always can.
bool canShareFiles() => true;

/// Shows the system share sheet for [bytes] as [fileName]; never
/// [ShareOutcome.refused], since the app has nowhere else to put them.
Future<ShareOutcome> sharePdfBytes(Uint8List bytes, String fileName) async {
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: pdfMediaType, name: fileName)],
      fileNameOverrides: [fileName],
    ),
  );
  return result.status == ShareResultStatus.dismissed
      ? ShareOutcome.cancelled
      : ShareOutcome.shared;
}

/// Saves [bytes] as [fileName] where the person chooses.
Future<void> downloadPdfBytes(Uint8List bytes, String fileName) =>
    saveFileBytes(fileName, bytes);

/// Writes [bytes] to a fresh temporary file named [fileName] and opens it
/// with the platform's PDF viewer; throws when the platform reports it did
/// not open.
Future<void> openPdfBytes(Uint8List bytes, String fileName) async {
  final dir = await Directory.systemTemp.createTemp(pdfOpenDirPrefix);
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  final opened = await launchUrl(
    Uri.file(file.path),
    mode: LaunchMode.externalApplication,
  );
  if (!opened) throw StateError('No viewer opened ${file.path}');
}
