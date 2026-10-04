import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show GalleryDesktop, GalleryPdfCard;
import 'package:cl_remote_store/cl_remote_store.dart'
    show EvaluationMemberMedia;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

/// A required public Q & A taking evidence, then a section holding only a
/// private Q & A.
final sdk.EvaluationTemplate _template = template(
  1,
  layout: const [
    sdk.EvaluationLayoutItem(11),
    sdk.EvaluationLayoutSection('Coach only', [12]),
  ],
  items: const [
    sdk.EvaluationQaItem(
      id: 11,
      question: 'What next',
      isRequired: true,
      allowEvidence: true,
    ),
    sdk.EvaluationQaItem(
      id: 12,
      question: 'Off-ice attitude',
      isPrivate: true,
      isRequired: true,
    ),
  ],
);

const Map<String, String> _headers = {'Authorization': 'Bearer t0k'};

/// A PDF of evidence [uuid] on item 11.
sdk.MediaLink _pdf(String uuid) => sdk.MediaLink(
  tag: '11',
  media: sdk.MediaRef(
    uuid: uuid,
    mimeType: 'application/pdf',
    filename: '$uuid.pdf',
  ),
  createdAtUtc: t0,
  updatedAtUtc: t0,
);

Future<StubEvaluations> _pump(
  WidgetTester tester, {
  List<sdk.EvaluationAnswer> answers = const [],
  sdk.EvaluationStatus status = sdk.EvaluationStatus.draft,
  List<sdk.MediaLink> evidence = const [],
  List<Uint8List>? opened,
}) async {
  final stub = StubEvaluations({
    5: staffView(5, status: status, answers: answers),
  });
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: StubTemplates({1: _template}),
      evaluations: stub,
      ownerMedia: EvaluationMemberMedia(evidence: {11: evidence}),
      authHeaders: _headers,
      child: EvaluationEditView(
        currentUser: viewer('coach', coach: true),
        evaluationId: 5,
        onBack: () {},
        onDeleted: () {},
        onTransferred: () {},
        onOpenPdfBytes: opened?.add ?? (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

void main() {
  group('Issue 173: a reopened draft shows its gaps', () {
    testWidgets('Issue 173: a draft with answers marks the missing ones as '
        'it opens', (tester) async {
      final stub = await _pump(
        tester,
        answers: const [sdk.EvaluationAnswer(itemId: 11, valueText: 'Edges')],
      );
      expect(find.text('An answer is required.'), findsOneWidget);
      expect(stub.calls, isEmpty);
    });

    testWidgets('Issue 173: a fresh draft opens without errors', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('An answer is required.'), findsNothing);
    });
  });

  group('Issue 173: evidence listed once in the editor', () {
    testWidgets('Issue 173: each file shows once, with its own remove '
        'action, and no second list', (tester) async {
      final stub = await _pump(
        tester,
        answers: const [sdk.EvaluationAnswer(itemId: 11, valueText: 'Edges')],
        evidence: [_pdf('e1'), _pdf('e2')],
      );
      expect(find.textContaining('Evidence 1'), findsNothing);
      expect(find.textContaining('e1.pdf'), findsNothing);
      expect(find.byType(GalleryPdfCard), findsNWidgets(2));
      expect(find.byType(GalleryDesktop), findsNothing);
      expect(find.text('Attach evidence'), findsOneWidget);
      final remove = find.bySemanticsLabel('Remove evidence');
      expect(remove, findsNWidgets(2));
      await tester.tap(remove.last);
      await tester.pumpAndSettle();
      expect(stub.calls, ['detach 5 11 e2']);
    });

    testWidgets('Issue 173: a PDF of evidence opens as bytes', (
      tester,
    ) async {
      final opened = <Uint8List>[];
      await _pump(
        tester,
        answers: const [sdk.EvaluationAnswer(itemId: 11, valueText: 'Edges')],
        evidence: [_pdf('e1')],
        opened: opened,
      );
      final card = tester.widget<GalleryPdfCard>(find.byType(GalleryPdfCard));
      expect(card.httpHeaders, _headers);
      card.onDownload();
      await tester.pumpAndSettle();
      expect(opened.single, fixedPdfBytes);
    });

    testWidgets('Issue 173: a finalized evaluation shows its evidence in the '
        'gallery, with nothing to remove', (tester) async {
      await _pump(
        tester,
        status: sdk.EvaluationStatus.saved,
        answers: const [sdk.EvaluationAnswer(itemId: 11, valueText: 'Edges')],
        evidence: [_pdf('e1')],
      );
      expect(find.byType(GalleryDesktop), findsOneWidget);
      expect(find.bySemanticsLabel('Remove evidence'), findsNothing);
      expect(find.text('Attach evidence'), findsNothing);
    });
  });
}
