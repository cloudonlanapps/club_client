// Platform backend: web uses `file_picker`; native (dart:io) prefers a direct
// foreground-friendly dialog on Linux and falls back to `file_picker`.
import 'identity_documents_picker_stub.dart'
    if (dart.library.io) 'identity_documents_picker_io.dart'
    as platform;
import 'picked_image.dart';

export 'picked_image.dart' show PickedImage, mimeTypeForExtension;

/// Signature for the identity-documents image picker.
///
/// Returns the picked image on success, or `null` if the user cancelled or
/// the platform returned no usable bytes. Errors should be thrown — callers
/// surface them (see `pickImageReportingErrors`); a normal cancel is silent.
typedef IdentityDocumentsPicker = Future<PickedImage?> Function();

/// Default picker: opens the native file dialog, restricted to JPG / JPEG /
/// PNG / WEBP and returns the bytes + a normalised mime type.
///
/// On Linux desktop the dialog is opened with `zenity --modal` (when zenity is
/// installed) so it reliably appears in front of the app window rather than
/// behind it; every other platform — and Linux without zenity — uses
/// `file_picker`. No cl_gallery_viewer or Riverpod involvement.
Future<PickedImage?> defaultIdentityDocumentsPicker() =>
    platform.pickImageFile();
