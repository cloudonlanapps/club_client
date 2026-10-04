import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';

/// One Q & A taking evidence.
final sdk.EvaluationTemplate _template = template(
  1,
  layout: const [sdk.EvaluationLayoutItem(14)],
  items: const [
    sdk.EvaluationQaItem(id: 14, question: 'Edge work', allowEvidence: true),
  ],
);

Future<StubEvaluations> _pump(
  WidgetTester tester, {
  List<sdk.EvaluationEvidence> evidence = const [],
}) async {
  final stub = StubEvaluations({
    5: staffView(
      5,
      answers: [
        sdk.EvaluationAnswer(
          itemId: 14,
          valueText: 'Clean',
          evidence: evidence,
        ),
      ],
    ),
  });
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      templates: StubTemplates({1: _template}),
      evaluations: stub,
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

/// Empties the answer and lets the autosave settle.
Future<void> _clear(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText), '');
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

const String _warning = 'Clearing this answer also removes its evidence.';

void main() {
  group('Issue 173: clearing an answer with evidence', () {
    testWidgets('Issue 173: asks first, and clears once confirmed', (
      tester,
    ) async {
      final stub = await _pump(
        tester,
        evidence: const [sdk.EvaluationEvidence(mediaUuid: 'e1')],
      );
      await _clear(tester);
      expect(find.text(_warning), findsOneWidget);
      expect(stub.calls, isEmpty);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['clear 5 14']);
    });

    testWidgets('Issue 173: cancelling keeps the answer and its evidence', (
      tester,
    ) async {
      final stub = await _pump(
        tester,
        evidence: const [sdk.EvaluationEvidence(mediaUuid: 'e1')],
      );
      await _clear(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(stub.calls, isEmpty);
      expect(find.text(_warning), findsNothing);
      expect(find.text('Clean'), findsOneWidget);
    });

    testWidgets('Issue 173: an answer without evidence clears without asking', (
      tester,
    ) async {
      final stub = await _pump(tester);
      await _clear(tester);
      expect(find.text(_warning), findsNothing);
      expect(stub.calls, ['clear 5 14']);
    });
  });
}
