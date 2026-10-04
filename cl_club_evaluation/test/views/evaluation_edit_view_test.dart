import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

/// A section of a required labelled rating (a coach note required for its
/// lowest level) and a yes / no taking evidence, then a required Q & A.
final sdk.EvaluationTemplate _template = template(
  1,
  layout: const [
    sdk.EvaluationLayoutSection('Skating', [11, 12]),
    sdk.EvaluationLayoutItem(13),
  ],
  items: const [
    sdk.EvaluationRatingItem(
      id: 11,
      question: 'Forward stride',
      isRequired: true,
      showCommentArea: true,
      requireCommentFor: [1],
      rateValues: [
        sdk.EvaluationRateLevel(value: 1, text: 'Needs work'),
        sdk.EvaluationRateLevel(value: 2, text: 'Good'),
      ],
    ),
    sdk.EvaluationYesNoItem(id: 12, question: 'Stops', allowEvidence: true),
    sdk.EvaluationQaItem(id: 13, question: 'What next', isRequired: true),
  ],
);

const List<sdk.EvaluationAnswer> _complete = [
  sdk.EvaluationAnswer(itemId: 11, valueNum: 2),
  sdk.EvaluationAnswer(itemId: 13, valueText: 'Edges'),
];

Future<StubEvaluations> _pump(
  WidgetTester tester, {
  sdk.EvaluationStatus status = sdk.EvaluationStatus.draft,
  List<sdk.EvaluationAnswer> answers = const [],
  Exception? saveError,
}) async {
  final stub = StubEvaluations({
    5: staffView(5, status: status, answers: answers),
  }, saveError: saveError);
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: StubTemplates({1: _template}),
      evaluations: stub,
      users: {'ana': userInfo('ana', 'Ana Rao')},
      child: EvaluationEditView(
        currentUser: viewer('coach', coach: true),
        evaluationId: 5,
        onBack: () {},
        onDeleted: () {},
        onTransferred: () {},
        onOpenPdfBytes: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

void main() {
  group('Issue 173: EvaluationEditView', () {
    testWidgets('Issue 173: a draft offers Finalize and Delete, and '
        'autosaves a settled answer', (tester) async {
      final stub = await _pump(tester);
      expect(find.text('Skating'), findsWidgets);
      expect(find.text('Ana Rao'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      for (final label in ['Finalize', 'Delete']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      for (final label in ['Transfer', 'Preview PDF']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('Publish'), findsNothing);
      await tester.tap(find.text('Good'));
      await tester.pump();
      expect(stub.calls, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(stub.calls, ['put 5 11 {valueNum: 2}']);
    });

    testWidgets('Issue 173: Finalize checks the form first and does not call '
        'the server with gaps', (tester) async {
      final stub = await _pump(tester);
      await tester.tap(find.text('Finalize'));
      await tester.pumpAndSettle();
      expect(stub.calls, isEmpty);
      expect(find.text('An answer is required.'), findsNWidgets(2));
    });

    testWidgets('Issue 173: the server INCOMPLETE marks the items it names', (
      tester,
    ) async {
      final stub = await _pump(
        tester,
        answers: _complete,
        saveError: const sdk.ServerException(
          statusCode: 422,
          code: sdk.SdkErrorCode.incomplete,
          message: 'incomplete',
          details: {
            'details': {
              'itemIds': [13],
            },
          },
        ),
      );
      await tester.tap(find.text('Finalize'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['save 5']);
      expect(find.text('Complete this answer.'), findsOneWidget);
    });

    testWidgets('Issue 173: a complete draft finalizes', (tester) async {
      final stub = await _pump(tester, answers: _complete);
      await tester.tap(find.text('Finalize'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['save 5']);
      expect(find.text('Evaluation finalized.'), findsOneWidget);
    });

    testWidgets('Issue 173: a saved evaluation offers Publish, Revert to '
        'draft and Transfer, read-only', (tester) async {
      final stub = await _pump(
        tester,
        status: sdk.EvaluationStatus.saved,
        answers: _complete,
      );
      for (final label in ['Publish', 'Revert to draft', 'Transfer']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Finalized'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Finalize'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('Needs work'));
      await tester.pump(const Duration(seconds: 1));
      expect(stub.calls, isEmpty);
    });

    testWidgets('Issue 173: a published evaluation offers Unpublish only', (
      tester,
    ) async {
      await _pump(
        tester,
        status: sdk.EvaluationStatus.published,
        answers: _complete,
      );
      expect(find.text('Unpublish'), findsOneWidget);
      for (final label in ['Finalize', 'Publish', 'Transfer', 'Delete']) {
        expect(find.text(label), findsNothing, reason: label);
      }
    });
  });
}
