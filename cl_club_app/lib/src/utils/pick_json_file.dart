import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// The extensions a JSON file is picked by; desktop filters are
/// case-sensitive, so both cases.
const List<String> jsonFileExtensions = ['json', 'JSON'];

/// What [pickJsonFile] answers in place of the platform's picker, when
/// set: the UI integration suite's stand-in, so a run on the desktop never
/// opens a file dialog and can hand it a file's bytes (club_client#400).
/// Null in the app.
@visibleForTesting
Future<Uint8List?> Function()? debugPickJsonFile;

/// Picks one JSON file with the platform's picker and resolves to its
/// bytes; `null` when none was chosen (club_client#27: a template to
/// import, #400: an application). [debugPickJsonFile] answers instead
/// while set.
Future<Uint8List?> pickJsonFile() async {
  final standIn = debugPickJsonFile;
  if (standIn != null) return standIn();
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: jsonFileExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.single.bytes;
}
