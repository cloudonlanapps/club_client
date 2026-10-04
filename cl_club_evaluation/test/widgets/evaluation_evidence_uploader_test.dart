import 'package:cl_club_evaluation/src/widgets/evaluation_evidence_uploader.dart';
import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show MediaKind, PickedMedia;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

const List<PickedMedia> _picked = [
  PickedMedia(
    bytes: [1, 2],
    filename: 'stride.png',
    kind: MediaKind.image,
    mimeType: 'image/png',
  ),
  PickedMedia(
    bytes: [3],
    filename: 'notes.pdf',
    kind: MediaKind.pdf,
    mimeType: 'application/pdf',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  StubEvaluations stub, {
  List<PickedMedia> picked = _picked,
}) async {
  await tester.pumpWidget(
    evaluationScope(
      evaluations: stub,
      child: EvaluationEvidenceUploader(
        evaluationId: 5,
        itemId: 12,
        pickFiles: ({required allowMultiple, required allowedKinds}) async =>
            picked,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 173: EvaluationEvidenceUploader', () {
    testWidgets('Issue 173: uploads each picked file as evidence on the item '
        'in one call', (tester) async {
      final stub = StubEvaluations({5: staffView(5)});
      await _pump(tester, stub);
      await tester.tap(find.text('Attach evidence'));
      await tester.pumpAndSettle();
      expect(stub.calls, [
        'upload 5 12 stride.png image/png',
        'upload 5 12 notes.pdf application/pdf',
      ]);
    });

    testWidgets('Issue 173: picking nothing uploads nothing', (tester) async {
      final stub = StubEvaluations({5: staffView(5)});
      await _pump(tester, stub, picked: const []);
      await tester.tap(find.text('Attach evidence'));
      await tester.pumpAndSettle();
      expect(stub.calls, isEmpty);
    });

    testWidgets("Issue 173: a refused upload shows the server's reason, not "
        'the exception', (tester) async {
      final stub = StubEvaluations(
        {5: staffView(5)},
        uploadError: const sdk.ServerException(
          statusCode: 422,
          code: sdk.SdkErrorCode.invalidEvidence,
          message: 'raw server text',
        ),
      );
      await _pump(tester, stub, picked: [_picked.first]);
      await tester.tap(find.text('Attach evidence'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['upload 5 12 stride.png image/png']);
      expect(
        find.text(
          'Evidence is an image, a video or a PDF, on a question that '
          'allows it.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
    });
  });
}
