import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../identity_documents/identity_documents_picker.dart'
    show PickedImage, defaultIdentityDocumentsPicker;

/// Picker function returning a [PickedImage] or `null` when the user cancels.
/// Production callers use [defaultIdentityDocumentsPicker]; tests inject one.
typedef ConfirmImagePicker = Future<PickedImage?> Function();

/// Runs [picker] and, if it *throws*, shows a destructive toast and returns
/// `null` — so a picker that fails to open (e.g. the native dialog erroring on
/// Linux) no longer fails silently (issue #709). A normal cancel — [picker]
/// returning `null` — stays silent. Use this anywhere the raw picker is
/// invoked so the failure is always visible to the user.
Future<PickedImage?> pickImageReportingErrors(
  BuildContext context, {
  ConfirmImagePicker picker = defaultIdentityDocumentsPicker,
}) async {
  try {
    return await picker();
  } on Object catch (e) {
    if (!context.mounted) return null;
    ShadToaster.of(context).show(
      ShadToast.destructive(
        description: Text("Couldn't open the image picker: $e"),
      ),
    );
    return null;
  }
}

/// Opens the native image picker, then a confirm-preview dialog. Returns the
/// picked image when the user confirms, else `null` (cancel / dismiss / no
/// pick). A picker error surfaces a toast (see [pickImageReportingErrors]).
/// Shared by the venue and group image affordances; the per-feature connected
/// widget owns the upload call that follows.
Future<PickedImage?> pickAndConfirmImage(
  BuildContext context, {
  ConfirmImagePicker picker = defaultIdentityDocumentsPicker,
  String title = 'Upload image',
}) async {
  final picked = await pickImageReportingErrors(context, picker: picker);
  if (picked == null || !context.mounted) return null;
  final confirmed = await showShadDialog<bool>(
    context: context,
    builder: (_) => ImagePreviewDialog(picked: picked, title: title),
  );
  return confirmed == true ? picked : null;
}

/// Preview dialog showing the picked image with Cancel / Upload actions.
class ImagePreviewDialog extends StatelessWidget {
  const ImagePreviewDialog({
    required this.picked,
    this.title = 'Upload image',
    super.key,
  });

  final PickedImage picked;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(title),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  Uint8List.fromList(picked.bytes),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.ghost(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
