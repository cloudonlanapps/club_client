import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart';

/// Demo screen for [IdentityDocumentsForm].
///
/// Fakes the host's three callback ports (upload / discard / submit) with
/// short delays so the form's lifecycle is visible without a real backend.
/// The form owns its own submitting state — the host just returns a future
/// from [handleSubmit].
class IdentityDocumentsFormScreen extends StatefulWidget {
  const IdentityDocumentsFormScreen({super.key});

  @override
  State<IdentityDocumentsFormScreen> createState() =>
      _IdentityDocumentsFormScreenState();
}

class _IdentityDocumentsFormScreenState
    extends State<IdentityDocumentsFormScreen> {
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

  Future<void> handleSubmit(Map<String, dynamic> value) async {
    final items =
        (value[kIdentityDocsFieldId] as List<IdentityDocumentSlot>?) ??
        const [];
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Submitted ${items.length} file(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IdentityDocumentsForm(
      onUpload: fakeUpload,
      onDiscard: fakeDiscard,
      onSubmit: handleSubmit,
    );
  }
}
