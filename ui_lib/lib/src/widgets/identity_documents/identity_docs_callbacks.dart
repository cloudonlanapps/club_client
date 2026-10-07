import 'identity_document_slot.dart';

/// Host callback contract for uploading bytes to the server.
typedef IdentityDocsUploadCallback =
    Future<IdentityDocumentSlot> Function({
      required List<int> bytes,
      required String filename,
      required String mimeType,
    });

/// Host callback contract for removing a slot (orphan or linked).
typedef IdentityDocsDiscardCallback =
    Future<void> Function(IdentityDocumentSlot slot);
