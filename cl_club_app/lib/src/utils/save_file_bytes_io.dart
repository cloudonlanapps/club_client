import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Asks where to save [bytes] as [fileName] and saves them there; resolves
/// to whether they were saved (`false` when the dialog was cancelled). On
/// Android and iOS the picker writes the file itself; on the desktop it
/// only names the path.
Future<bool> saveFileBytes(String fileName, Uint8List bytes) async {
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    bytes: bytes,
  );
  if (path == null) return false;
  if (!Platform.isAndroid && !Platform.isIOS) {
    await File(path).writeAsBytes(bytes, flush: true);
  }
  return true;
}
