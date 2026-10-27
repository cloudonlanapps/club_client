import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'save_file_bytes_web.dart';
import 'share_outcome.dart';

/// The name of the error a browser's share sheet rejects with when the
/// person closes it without choosing anything.
const String shareAbortError = 'AbortError';

/// Name of the probe file asked about in [canShareFiles].
const String _probeName = 'probe.pdf';

/// Whether this browser can share a PDF file (Web Share with files).
bool canShareFiles() {
  final navigator = web.window.navigator;
  if (!navigator.has('canShare')) return false;
  return navigator.canShare(
    web.ShareData(files: [_pdfFile(Uint8List(0), _probeName)].toJS),
  );
}

/// Shows the browser's share sheet for [bytes] as [fileName].
Future<ShareOutcome> sharePdfBytes(Uint8List bytes, String fileName) async {
  final data = web.ShareData(files: [_pdfFile(bytes, fileName)].toJS);
  try {
    await web.window.navigator.share(data).toDart;
    return ShareOutcome.shared;
  } on Object catch (error) {
    return _errorName(error) == shareAbortError
        ? ShareOutcome.cancelled
        : ShareOutcome.refused;
  }
}

/// Saves [bytes] as [fileName] to the browser's download folder.
Future<void> downloadPdfBytes(Uint8List bytes, String fileName) =>
    saveFileBytes(fileName, bytes);

/// Not offered in a browser, which downloads instead.
Future<void> openPdfBytes(Uint8List bytes, String fileName) =>
    downloadPdfBytes(bytes, fileName);

web.File _pdfFile(Uint8List bytes, String fileName) => web.File(
  [bytes.toJS].toJS,
  fileName,
  web.FilePropertyBag(type: pdfMediaType),
);

/// The `name` of the `DOMException` a promise rejected with; null for any
/// other error.
String? _errorName(Object error) {
  if (!error.isA<web.DOMException>()) return null;
  // A JS value converts to itself.
  return (error.jsify()! as web.DOMException).name;
}
