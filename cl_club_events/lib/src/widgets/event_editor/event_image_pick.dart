import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ConfirmImagePicker, PickedImage, pickImageReportingErrors;

import 'event_image_preview_dialog.dart';

/// Opens the native image picker, then a confirm preview. Returns the picked
/// image when the user confirms, else `null`.
Future<PickedImage?> pickAndConfirmEventImage(
  BuildContext context, {
  required ConfirmImagePicker picker,
}) async {
  final picked = await pickImageReportingErrors(context, picker: picker);
  if (picked == null || !context.mounted) return null;
  final confirmed = await showShadDialog<bool>(
    context: context,
    builder: (_) => EventImagePreviewDialog(picked: picked),
  );
  return confirmed == true ? picked : null;
}
