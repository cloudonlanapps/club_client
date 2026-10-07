import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/constants/identity_documents.dart'
    show kIdentityDocumentMaxBytes;
import 'package:ui_lib/src/widgets/identity_documents/identity_document_rejection_reason.dart'
    show IdentityDocumentRejectionReason;
import 'package:ui_lib/src/widgets/identity_documents/identity_documents_upload_validators.dart'
    show IdentityDocumentsUploadValidators;
import 'package:ui_lib/ui_lib.dart';

const Size _kSurface = Size(1024, 1400);

/// A queue-based picker fake: each call returns the next entry, or null when
/// the queue is exhausted (simulating the user cancelling the dialog).
class _FakePicker {
  _FakePicker(this.queue);
  final List<PickedImage?> queue;
  int calls = 0;

  Future<PickedImage?> pick() async {
    if (calls >= queue.length) return null;
    return queue[calls++];
  }
}

PickedImage _image({
  required String mime,
  required int size,
  String filename = 'doc.jpg',
}) {
  return PickedImage(
    bytes: List<int>.filled(size, 0),
    filename: filename,
    mimeType: mime,
  );
}

class _FakeHost {
  _FakeHost();
  int uploadCalls = 0;
  int discardCalls = 0;
  IdentityDocumentSlot? lastDiscarded;

  Future<IdentityDocumentSlot> upload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final id = 'fake-${uploadCalls++}';
    return IdentityDocumentSlot(
      id: id,
      uri: 'https://example.test/$id',
      mimeType: mimeType,
      sizeBytes: bytes.length,
      fileName: filename,
    );
  }

  Future<void> discard(IdentityDocumentSlot slot) async {
    discardCalls++;
    lastDiscarded = slot;
  }
}

Widget _wrap(Widget child) {
  return ShadApp(home: Scaffold(body: child));
}

Future<void> _setSurface(WidgetTester tester, [Size size = _kSurface]) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('Issue 383: IdentityDocumentsUploadValidators', () {
    test('Issue 383: accepts JPG within size cap', () {
      final r = IdentityDocumentsUploadValidators.acceptFile(
        mimeType: 'image/jpeg',
        sizeBytes: 1024 * 100,
      );
      expect(r.accepted, isTrue);
      expect(r.reason, isNull);
    });

    test('Issue 383: rejects unsupported mime type', () {
      final r = IdentityDocumentsUploadValidators.acceptFile(
        mimeType: 'text/plain',
        sizeBytes: 100,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, IdentityDocumentRejectionReason.unsupportedMimeType);
    });

    test('Issue 383: rejects files over the byte cap', () {
      final r = IdentityDocumentsUploadValidators.acceptFile(
        mimeType: 'image/png',
        sizeBytes: kIdentityDocumentMaxBytes + 1,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, IdentityDocumentRejectionReason.fileTooLarge);
    });

    test('Issue 383: rejects application/pdf (PDFs not accepted)', () {
      final r = IdentityDocumentsUploadValidators.acceptFile(
        mimeType: 'application/pdf',
        sizeBytes: 1024,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, IdentityDocumentRejectionReason.unsupportedMimeType);
    });
  });

  group('Issue 383: IdentityDocumentsUploader — picker lifecycle', () {
    testWidgets(
      'Issue 383: picking a valid file calls onUpload and adds a card',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        final picker = _FakePicker([
          _image(mime: 'image/jpeg', size: 1024, filename: 'pan.jpg'),
        ]);
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              picker: picker.pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(host.uploadCalls, 1);
      },
    );

    testWidgets(
      'Issue 383: rejected pick (wrong type) shows the reason under the cards',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        final picker = _FakePicker([
          _image(mime: 'text/plain', size: 100, filename: 'notes.txt'),
        ]);
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              picker: picker.pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(
          find.text(
            "We can't open that file. Please pick a photo (JPG, PNG, or WEBP).",
          ),
          findsOneWidget,
        );
        expect(host.uploadCalls, 0);
      },
    );

    testWidgets(
      'Issue 383: rejected pick (too large) shows the reason under the cards',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        final picker = _FakePicker([
          _image(
            mime: 'image/jpeg',
            size: kIdentityDocumentMaxBytes + 1,
            filename: 'huge.jpg',
          ),
        ]);
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              picker: picker.pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(
          find.text('That file is too big. Please pick one under 5 MB.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Issue 383: at maxCount, no add (+) card is rendered',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              initialItems: const [
                IdentityDocumentSlot(
                  id: 'a',
                  uri: 'https://example.test/a',
                  mimeType: 'image/jpeg',
                  sizeBytes: 1024,
                ),
                IdentityDocumentSlot(
                  id: 'b',
                  uri: 'https://example.test/b',
                  mimeType: 'image/png',
                  sizeBytes: 1024,
                ),
              ],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        expect(find.byIcon(Icons.add), findsNothing);
      },
    );
  });

  group('Issue 383: IdentityDocumentsUploader — discard', () {
    testWidgets(
      'Issue 383: tapping the X on a card calls onDiscard',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        const seed = IdentityDocumentSlot(
          id: 'seed-1',
          uri: 'https://example.test/seed-1',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
          fileName: 'seed.jpg',
        );
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              initialItems: const [seed],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();
        expect(host.discardCalls, 1);
        expect(host.lastDiscarded?.id, 'seed-1');
      },
    );
  });

  group('Issue 51: IdentityDocumentsUploader saves on its own', () {
    testWidgets(
      'Issue 51: it has no form, no checkbox and no button',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        expect(find.byType(ShadForm), findsNothing);
        expect(find.byType(ShadCheckbox), findsNothing);
        expect(find.byType(ShadButton), findsNothing);
      },
    );

    testWidgets(
      'Issue 51: an upload and a removal each report the documents',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        final reported = <List<IdentityDocumentSlot>>[];
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              picker: _FakePicker([
                _image(mime: 'image/jpeg', size: 1024, filename: 'id.jpg'),
              ]).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onChanged: reported.add,
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(reported.last.map((s) => s.id), ['fake-0']);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(host.discardCalls, 1);
        expect(reported.last, isEmpty);
      },
    );

    testWidgets(
      'Issue 51: disabled, it offers no add card and no remove button',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              enabled: false,
              initialItems: const [
                IdentityDocumentSlot(
                  id: 'a',
                  uri: 'https://example.test/a',
                  mimeType: 'image/jpeg',
                  sizeBytes: 1024,
                ),
              ],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets(
      'Issue 51: fits a phone-sized viewport (390x844) without overflow',
      (tester) async {
        await _setSurface(tester, const Size(390, 844));
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsUploader(
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
