import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// The extensions a JSON file is picked by; desktop filters are
/// case-sensitive, so both cases.
const List<String> jsonFileExtensions = ['json', 'JSON'];

/// Picks one JSON file with the platform's picker and resolves to its
/// bytes; `null` when none was chosen (club_client#27: a template to
/// import).
Future<Uint8List?> pickJsonFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: jsonFileExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.single.bytes;
}
