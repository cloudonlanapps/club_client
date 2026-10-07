import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart';

/// Demo screen for [IdentityDocumentsUploader].
///
/// Fakes the host's upload and discard with short delays so the uploader's
/// lifecycle is visible without a backend.
class IdentityDocumentsScreen extends StatefulWidget {
  const IdentityDocumentsScreen({super.key});

  @override
  State<IdentityDocumentsScreen> createState() =>
      _IdentityDocumentsScreenState();
}

class _IdentityDocumentsScreenState extends State<IdentityDocumentsScreen> {
  int seq = 0;

  Future<IdentityDocumentSlot> fakeUpload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final id = 'demo-${seq++}';
    return IdentityDocumentSlot(
      id: id,
      // Demo placeholder — picsum returns a stable image per seed.
      uri: 'https://picsum.photos/seed/$id/640/400',
      mimeType: mimeType.isEmpty ? 'image/jpeg' : mimeType,
      sizeBytes: bytes.length,
      fileName: filename,
    );
  }

  Future<void> fakeDiscard(IdentityDocumentSlot _) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return IdentityDocumentsUploader(
      onUpload: fakeUpload,
      onDiscard: fakeDiscard,
    );
  }
}
