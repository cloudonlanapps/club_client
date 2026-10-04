import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show GalleryDesktop, GalleryPdfCard;
import 'package:cl_remote_store/cl_remote_store.dart'
    show EvaluationMemberMedia, MediaBytesReader;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../support/evaluation_scope.dart';

/// The session headers the scope hands out.
const Map<String, String> _headers = {'Authorization': 'Bearer t0k'};

/// A PDF link [uuid] under [tag].
sdk.MediaLink _pdf(String tag, String uuid) => sdk.MediaLink(
  tag: tag,
  media: sdk.MediaRef(
    uuid: uuid,
    mimeType: 'application/pdf',
    filename: '$uuid.pdf',
  ),
  createdAtUtc: t0,
  updatedAtUtc: t0,
);

/// A published review of ana with one yes / no taking evidence.
final sdk.EvaluationMemberView _review = sdk.EvaluationMemberView(
  id: 1,
  createdFor: 'ana',
  createdBy: 'coach',
  status: sdk.EvaluationStatus.published,
  publishedAtUtc: t0,
  template: const sdk.EvaluationMemberTemplate(
    id: 1,
    name: 'Skating',
    layout: [sdk.EvaluationLayoutItem(11)],
    items: [
      sdk.EvaluationYesNoItem(id: 11, question: 'Stops', allowEvidence: true),
    ],
  ),
  answers: const [sdk.EvaluationAnswer(itemId: 11, valueNum: 1)],
);

/// The member copy and one evidence PDF on item 11.
final EvaluationMemberMedia _memberMedia = EvaluationMemberMedia(
  memberCopy: _pdf(sdk.EvaluationMediaTags.memberCopy, 'copy-uuid'),
  evidence: {
    11: [_pdf('11', 'ev-uuid')],
  },
);

/// A reader recording the uuid of every file it reads.
MediaBytesReader _recording(List<String> read) => (media) async {
  read.add(media.uuid);
  return fixedPdfBytes;
};

Future<void> _pumpRead(
  WidgetTester tester, {
  required List<Uint8List> opened,
  MediaBytesReader readBytes = fixedPdfReader,
}) async {
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      memberViews: [_review],
      memberMedia: _memberMedia,
      readBytes: readBytes,
      authHeaders: _headers,
      child: EvaluationReadView(
        currentUser: viewer('ana'),
        username: 'ana',
        evaluationId: 1,
        onBack: () {},
        onOpenPdfBytes: opened.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens the gallery's first PDF as its download action would.
Future<void> _openGalleryPdf(WidgetTester tester) async {
  final gallery = tester.widget<GalleryDesktop>(find.byType(GalleryDesktop));
  gallery.onPdfDownload!(gallery.items.first.url);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 173: private evaluation media on the read view', () {
    testWidgets('Issue 173: the evidence gallery sends the session headers', (
      tester,
    ) async {
      await _pumpRead(tester, opened: []);
      final gallery = tester.widget<GalleryDesktop>(
        find.byType(GalleryDesktop),
      );
      expect(gallery.httpHeaders, _headers);
    });

    testWidgets('Issue 173: the download icon downloads the member copy '
        'with the session and hands over its bytes', (tester) async {
      final opened = <Uint8List>[];
      final read = <String>[];
      await _pumpRead(tester, opened: opened, readBytes: _recording(read));
      await tester.tap(find.byIcon(LucideIcons.download));
      await tester.pumpAndSettle();
      expect(read, ['copy-uuid']);
      expect(opened.single, fixedPdfBytes);
    });

    testWidgets('Issue 173: an evidence PDF opens as bytes', (tester) async {
      final opened = <Uint8List>[];
      final read = <String>[];
      await _pumpRead(tester, opened: opened, readBytes: _recording(read));
      await _openGalleryPdf(tester);
      expect(read, ['ev-uuid']);
      expect(opened.single, fixedPdfBytes);
    });

    testWidgets('Issue 173: a refused download shows a friendly toast and '
        'opens nothing', (tester) async {
      final opened = <Uint8List>[];
      await _pumpRead(
        tester,
        opened: opened,
        readBytes: (media) async => throw const sdk.ServerException(
          statusCode: 403,
          code: 'FORBIDDEN',
          message: 'raw server text',
        ),
      );
      await tester.tap(find.byIcon(LucideIcons.download));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
      expect(find.text('Could not open the PDF.'), findsOneWidget);
      expect(find.textContaining('raw server text'), findsNothing);
    });
  });

  group("Issue 173: private evidence in the owner's editor", () {
    final edgeWork = template(
      1,
      layout: const [sdk.EvaluationLayoutItem(14)],
      items: const [
        sdk.EvaluationQaItem(
          id: 14,
          question: 'Edge work',
          allowEvidence: true,
        ),
      ],
    );

    Future<void> pumpEdit(
      WidgetTester tester, {
      required List<Uint8List> opened,
      required List<String> read,
    }) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          templates: StubTemplates({1: edgeWork}),
          evaluations: StubEvaluations({
            5: staffView(
              5,
              answers: const [
                sdk.EvaluationAnswer(
                  itemId: 14,
                  valueText: 'Clean',
                  evidence: [sdk.EvaluationEvidence(mediaUuid: 'e1')],
                ),
              ],
            ),
          }),
          ownerMedia: EvaluationMemberMedia(
            evidence: {
              14: [_pdf('14', 'e1')],
            },
          ),
          readBytes: _recording(read),
          authHeaders: _headers,
          child: EvaluationEditView(
            currentUser: viewer('coach', coach: true),
            evaluationId: 5,
            onBack: () {},
            onDeleted: () {},
            onTransferred: () {},
            onOpenPdfBytes: opened.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Issue 173: the evidence card sends the session headers and '
        'an evidence PDF opens as bytes', (tester) async {
      final opened = <Uint8List>[];
      final read = <String>[];
      await pumpEdit(tester, opened: opened, read: read);
      final card = tester.widget<GalleryPdfCard>(find.byType(GalleryPdfCard));
      expect(card.httpHeaders, _headers);
      card.onDownload();
      await tester.pumpAndSettle();
      expect(read, ['e1']);
      expect(opened.single, fixedPdfBytes);
    });
  });
}
