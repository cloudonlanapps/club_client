import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// How long the object URL outlives the click that starts the download.
const Duration downloadUrlLifetime = Duration(minutes: 1);

/// Downloads [bytes] as [fileName] through an object URL; resolves to
/// `true`, since the browser decides where the file goes.
Future<bool> saveFileBytes(String fileName, Uint8List bytes) async {
  final url = web.URL.createObjectURL(web.Blob([bytes.toJS].toJS));
  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  unawaited(
    Future<void>.delayed(
      downloadUrlLifetime,
      () => web.URL.revokeObjectURL(url),
    ),
  );
  return true;
}
