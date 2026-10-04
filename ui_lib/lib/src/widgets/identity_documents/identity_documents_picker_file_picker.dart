import 'package:file_picker/file_picker.dart';

import 'picked_image.dart';

/// Picks an image via the `file_picker` plugin. Works on every platform the
/// plugin supports; used directly on web and as the Linux fallback when zenity
/// is unavailable. Returns `null` on cancel; throws on a platform error.
Future<PickedImage?> pickViaFilePicker() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    // Accept both cases — `file_picker`'s desktop filters are case-sensitive.
    allowedExtensions: [
      for (final ext in kPickerImageExtensions) ...[ext, ext.toUpperCase()],
    ],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;
  return PickedImage(
    bytes: bytes,
    filename: file.name,
    mimeType: mimeTypeForExtension(file.extension),
  );
}
