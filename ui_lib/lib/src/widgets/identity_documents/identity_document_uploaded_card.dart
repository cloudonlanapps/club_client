import 'package:flutter/material.dart';

import '../../constants/identity_document_sizes.dart';
import 'identity_document_card_frame.dart';
import 'identity_document_remove_button.dart';
import 'identity_document_slot.dart';
import 'identity_document_slot_preview.dart';

/// The card of an uploaded identity document: its image, opening the
/// preview on a tap, with a remove button while [onRemove] is given.
class IdentityDocumentUploadedCard extends StatelessWidget {
  const IdentityDocumentUploadedCard({
    required this.slot,
    required this.onTap,
    required this.httpHeaders,
    this.onRemove,
    super.key,
  });

  /// The uploaded document.
  final IdentityDocumentSlot slot;

  /// Opens the preview; null leaves the card inert.
  final VoidCallback? onTap;

  /// Removes the document; null hides the button.
  final VoidCallback? onRemove;

  /// Headers sent with the image request.
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    final remove = onRemove;
    return IdentityDocumentCardFrame(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IdentityDocumentSlotPreview(slot: slot, httpHeaders: httpHeaders),
          if (remove != null)
            Positioned(
              top: IdentityDocumentSizes.removeInset,
              right: IdentityDocumentSizes.removeInset,
              child: IdentityDocumentRemoveButton(onPressed: remove),
            ),
        ],
      ),
    );
  }
}
