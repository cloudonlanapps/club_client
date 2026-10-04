import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// The PDF media type.
const String pdfMediaType = 'application/pdf';

/// The browsing context a preview opens in.
const String pdfPreviewTarget = '_blank';

/// Opens [bytes] as a PDF in a new browser tab through an object URL;
/// returns whether the browser opened a window.
Future<bool> openPdfBytes(Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: pdfMediaType),
  );
  final url = web.URL.createObjectURL(blob);
  return web.window.open(url, pdfPreviewTarget) != null;
}
