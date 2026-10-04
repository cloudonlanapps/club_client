import 'dart:convert';
import 'dart:io';

import 'identity_documents_picker_file_picker.dart';
import 'picked_image.dart';

/// Native (dart:io) picker backend.
///
/// On Linux the `file_picker` plugin shells out to `zenity` without the
/// `--modal` hint, so the file dialog opens as a detached top-level window the
/// window manager often places *behind* the app — the user sees nothing happen
/// (issue #709). When zenity is installed we invoke it directly with `--modal`
/// so the dialog reliably comes to the foreground. Everything else — other
/// desktop/mobile platforms, or Linux without zenity — uses `file_picker`.
Future<PickedImage?> pickImageFile() async {
  if (Platform.isLinux) {
    try {
      return await _pickViaZenity();
    } on _ZenityUnavailable {
      return pickViaFilePicker();
    }
  }
  return pickViaFilePicker();
}

/// Command-line arguments for a zenity file-selection dialog restricted to
/// [extensions]. `--modal` is the fix for issue #709: it sets the modal window
/// hint so the dialog is raised in front of the app instead of behind it.
///
/// Pure (no I/O) so it can be unit-tested.
List<String> buildZenityArguments({
  required String title,
  required List<String> extensions,
}) {
  // zenity filter syntax: `--file-filter=NAME | PATTERN1 PATTERN2 ...`.
  // Desktop pattern matching is case-sensitive, so emit both cases.
  final patterns = [
    for (final ext in extensions) ...['*.$ext', '*.${ext.toUpperCase()}'],
  ].join(' ');
  return [
    '--file-selection',
    '--modal',
    '--title',
    title,
    '--file-filter=Images | $patterns',
  ];
}

/// Marker that zenity isn't installed, so the caller should fall back to
/// `file_picker` rather than surfacing an error.
class _ZenityUnavailable implements Exception {
  const _ZenityUnavailable();
}

Future<PickedImage?> _pickViaZenity() async {
  late final ProcessResult result;
  try {
    result = await Process.run(
      'zenity',
      buildZenityArguments(
        title: 'Select image',
        extensions: kPickerImageExtensions,
      ),
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  } on ProcessException {
    // Binary not found / not launchable → let the caller fall back.
    throw const _ZenityUnavailable();
  }

  switch (result.exitCode) {
    case 0:
      final path = (result.stdout as String).trim();
      if (path.isEmpty) return null;
      final bytes = await File(path).readAsBytes();
      final filename = path.split(Platform.pathSeparator).last;
      return PickedImage(
        bytes: bytes,
        filename: filename,
        mimeType: mimeTypeForExtension(_extensionOf(filename)),
      );
    case 1:
      // User cancelled or closed the dialog — stay silent.
      return null;
    default:
      final err = (result.stderr as String).trim();
      throw Exception(
        'Image chooser failed (zenity exit ${result.exitCode})'
        '${err.isEmpty ? '' : ': $err'}',
      );
  }
}

String? _extensionOf(String filename) {
  final dot = filename.lastIndexOf('.');
  return dot == -1 ? null : filename.substring(dot + 1);
}
