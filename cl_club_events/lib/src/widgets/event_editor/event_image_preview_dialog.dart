import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PickedImage;

/// Preview dialog showing the picked image with Cancel / Upload actions.
class EventImagePreviewDialog extends StatelessWidget {
  const EventImagePreviewDialog({required this.picked, super.key});

  final PickedImage picked;

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Upload image'),
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
