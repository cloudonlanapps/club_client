import 'package:flutter/material.dart';

import '../credentialed_network_image.dart';
import 'identity_document_image_placeholder.dart';
import 'identity_document_slot.dart';

/// The image of an uploaded identity document, filling its card.
class IdentityDocumentSlotPreview extends StatelessWidget {
  const IdentityDocumentSlotPreview({
    required this.slot,
    required this.httpHeaders,
    super.key,
  });

  /// The uploaded document.
  final IdentityDocumentSlot slot;

  /// Headers sent with the image request.
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    return CredentialedNetworkImage(
      imageUrl: slot.uri,
      httpHeaders: httpHeaders,
      fit: BoxFit.cover,
      errorBuilder: (_) =>
          IdentityDocumentImagePlaceholder(filename: slot.fileName),
    );
  }
}
