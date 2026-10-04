import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

Future<void> _acceptPrivacy(WidgetTester tester) async {
  final innerCheckbox = find.descendant(
    of: find.byType(ShadCheckboxFormField),
    matching: find.byType(ShadCheckbox),
  );
  tester.widget<ShadCheckbox>(innerCheckbox).onChanged?.call(true);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 383: IdentityDocumentsFormValidators', () {
    test('Issue 383: accepts JPG within size cap', () {
      final r = IdentityDocumentsFormValidators.acceptFile(
        mimeType: 'image/jpeg',
        sizeBytes: 1024 * 100,
      );
      expect(r.accepted, isTrue);
      expect(r.reason, isNull);
    });

    test('Issue 383: rejects unsupported mime type', () {
      final r = IdentityDocumentsFormValidators.acceptFile(
        mimeType: 'text/plain',
        sizeBytes: 100,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, IdentityDocumentRejectionReason.unsupportedMimeType);
    });

    test('Issue 383: rejects files over the byte cap', () {
      final r = IdentityDocumentsFormValidators.acceptFile(
        mimeType: 'image/png',
        sizeBytes: kIdentityDocumentMaxBytes + 1,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, IdentityDocumentRejectionReason.fileTooLarge);
    });

    test('Issue 383: rejects application/pdf (PDFs not accepted)', () {
      final r = IdentityDocumentsFormValidators.acceptFile(
        mimeType: 'application/pdf',
        sizeBytes: 1024,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, IdentityDocumentRejectionReason.unsupportedMimeType);
    });
  });

  group('Issue 383: IdentityDocumentsForm — initial state', () {
    testWidgets(
      'Issue 383: renders title, tips, field, checkbox, submit',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
            ),
          ),
        );
        // Tips accordion title is visible but the bullet body is collapsed
        // by default — user opens it on demand.
        expect(find.text('Tips for a clean upload'), findsOneWidget);
        expect(
          find.textContaining('Regular or masked Aadhaar'),
          findsNothing,
        );
        expect(find.byType(ShadCheckboxFormField), findsOneWidget);
        expect(find.text('Submit'), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 383: submit disabled when empty even with privacy checked',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
            ),
          ),
        );
        await _acceptPrivacy(tester);
        final btn = tester.widget<ShadButton>(
          find.ancestor(
            of: find.text('Submit'),
            matching: find.byType(ShadButton),
          ),
        );
        expect(btn.onPressed, isNull);
      },
    );

    testWidgets(
      'Issue 383: submit disabled when items present but privacy unchecked',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              initialItems: const [
                IdentityDocumentSlot(
                  id: 'seed-1',
                  uri: 'https://example.test/seed-1',
                  mimeType: 'image/jpeg',
                  sizeBytes: 1024,
                  fileName: 'seed.jpg',
                ),
              ],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
            ),
          ),
        );
        final btn = tester.widget<ShadButton>(
          find.ancestor(
            of: find.text('Submit'),
            matching: find.byType(ShadButton),
          ),
        );
        expect(btn.onPressed, isNull);
      },
    );
  });

  group('Issue 383: IdentityDocumentsForm — picker lifecycle', () {
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
            IdentityDocumentsForm(
              picker: picker.pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
            ),
          ),
        );
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(host.uploadCalls, 1);
      },
    );

    testWidgets(
      'Issue 383: rejected pick (wrong type) shows inline field error',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        final picker = _FakePicker([
          _image(mime: 'text/plain', size: 100, filename: 'notes.txt'),
        ]);
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              picker: picker.pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
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
      'Issue 383: rejected pick (too large) shows inline field error',
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
            IdentityDocumentsForm(
              picker: picker.pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
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
            IdentityDocumentsForm(
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
              onSubmit: (_) async {},
            ),
          ),
        );
        expect(find.byIcon(Icons.add), findsNothing);
      },
    );
  });

  group('Issue 383: IdentityDocumentsForm — discard', () {
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
            IdentityDocumentsForm(
              initialItems: const [seed],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
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

  group('Issue 383: IdentityDocumentsForm — submit', () {
    testWidgets(
      'Issue 383: with item + privacy, submit returns expected value map',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        Map<String, dynamic>? submitted;
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              initialItems: const [
                IdentityDocumentSlot(
                  id: 'seed-1',
                  uri: 'https://example.test/seed-1',
                  mimeType: 'image/jpeg',
                  sizeBytes: 1024,
                  fileName: 'seed.jpg',
                ),
              ],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (v) async {
                submitted = v;
              },
            ),
          ),
        );
        await _acceptPrivacy(tester);
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();
        expect(submitted, isNotNull);
        final slots =
            submitted![kIdentityDocsFieldId] as List<IdentityDocumentSlot>;
        expect(slots, hasLength(1));
        expect(slots.first.id, 'seed-1');
        expect(submitted![kPrivacyAcceptedFieldId], isTrue);
      },
    );

    testWidgets(
      'Issue 383: form shows "Submitting…" while onSubmit is in flight',
      (tester) async {
        await _setSurface(tester);
        final host = _FakeHost();
        final completer = Completer<void>();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              initialItems: const [
                IdentityDocumentSlot(
                  id: 's',
                  uri: 'https://example.test/s',
                  mimeType: 'image/jpeg',
                  sizeBytes: 1024,
                ),
              ],
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) => completer.future,
            ),
          ),
        );
        await _acceptPrivacy(tester);
        await tester.tap(find.text('Submit'));
        await tester.pump();
        expect(find.text('Submitting…'), findsOneWidget);
        expect(find.text('Submit'), findsNothing);

        completer.complete();
        await tester.pumpAndSettle();
        expect(find.text('Submit'), findsOneWidget);
        expect(find.text('Submitting…'), findsNothing);
      },
    );
  });

  group('Issue 383: IdentityDocumentsForm — layout parity', () {
    testWidgets(
      'Issue 383: fits a phone-sized viewport (390x844) without overflow',
      (tester) async {
        await _setSurface(tester, const Size(390, 844));
        final host = _FakeHost();
        await tester.pumpWidget(
          _wrap(
            IdentityDocumentsForm(
              picker: _FakePicker(const []).pick,
              onUpload: host.upload,
              onDiscard: host.discard,
              onSubmit: (_) async {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Submit'), findsOneWidget);
      },
    );
  });
}
