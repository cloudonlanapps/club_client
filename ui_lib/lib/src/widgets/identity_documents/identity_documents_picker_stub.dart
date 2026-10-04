import 'identity_documents_picker_file_picker.dart';
import 'picked_image.dart';

/// Web / default backend: delegates straight to `file_picker`. The Linux
/// foreground handling lives in the dart:io backend.
Future<PickedImage?> pickImageFile() => pickViaFilePicker();
