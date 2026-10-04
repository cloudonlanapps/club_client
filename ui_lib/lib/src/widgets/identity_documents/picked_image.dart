import 'package:flutter/foundation.dart';

/// Image file extensions the identity-documents / image pickers accept.
/// Lower-case, no leading dot. Shared by every platform picker backend so the
/// file dialog filter stays consistent across `file_picker` and the direct
/// zenity invocation on Linux.
const List<String> kPickerImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

/// A picked-but-not-yet-uploaded image file.
@immutable
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final List<int> bytes;
  final String filename;
  final String mimeType;
}

/// Normalised image mime type for a file [extension] (with or without a
/// leading dot, case-insensitive). Defaults to `image/jpeg` for anything
/// outside the picker's allowed set, mirroring the historical behaviour.
String mimeTypeForExtension(String? extension) {
  final ext = extension?.toLowerCase().replaceFirst(RegExp(r'^\.'), '');
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
