import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Demo screen for [IdentityDocumentsUploader] and
/// [IdentityDocumentsConsentForm].
///
/// Fakes the host's upload and discard with short delays so the uploader's
/// lifecycle is visible without a backend, and plays the host's part for
/// the consent form: a Submit button that validates it.
class IdentityDocumentsScreen extends StatefulWidget {
  const IdentityDocumentsScreen({super.key});

  @override
  State<IdentityDocumentsScreen> createState() =>
      _IdentityDocumentsScreenState();
}

class _IdentityDocumentsScreenState extends State<IdentityDocumentsScreen> {
  final consentKey = GlobalKey<IdentityDocumentsConsentFormState>();
  List<IdentityDocumentSlot> items = const [];
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

  void handleSubmit() {
    if (consentKey.currentState?.validate() == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Submitted ${items.length} file(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        IdentityDocumentsUploader(
          onUpload: fakeUpload,
          onDiscard: fakeDiscard,
          onChanged: (next) => setState(() => items = next),
        ),
        IdentityDocumentsConsentForm(key: consentKey),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            enabled: items.isNotEmpty,
            onPressed: items.isEmpty ? null : handleSubmit,
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}
