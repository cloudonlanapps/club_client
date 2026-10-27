import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_scope.dart';
import '../support/pdf_action.dart';

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
        pdfAction: recordingPdfAction(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

/// Empties the answer and pauses past the autosave delay, the field still
/// focused.
Future<void> _empty(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText), '');
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Takes the focus off the answer, as tapping elsewhere does.
Future<void> _leave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// Empties the answer, lets the autosave settle and leaves the field.
Future<void> _clear(WidgetTester tester) async {
  await _empty(tester);
  await _leave(tester);
}

/// The answer as the field shows it.
String _shown(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

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
  group('Issue 164: no clear prompt while typing', () {
    const evidence = [sdk.EvaluationEvidence(mediaUuid: 'e1')];

    testWidgets('Issue 164: emptying the answer asks nothing while the field '
        'has the focus', (tester) async {
      final stub = await _pump(tester, evidence: evidence);
      await _empty(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(_warning), findsNothing);
      expect(stub.calls, isEmpty);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('Issue 164: leaving the field still empty asks, and clears '
        'once confirmed', (tester) async {
      final stub = await _pump(tester, evidence: evidence);
      await _empty(tester);
      await _leave(tester);
      expect(find.text(_warning), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(stub.calls, ['clear 5 14']);
    });

    testWidgets('Issue 164: retyping before leaving writes the new answer '
        'without asking', (tester) async {
      final stub = await _pump(tester, evidence: evidence);
      await _empty(tester);
      await tester.enterText(find.byType(EditableText), 'Sharp');
      await tester.pump(const Duration(seconds: 1));
      await _leave(tester);
      expect(find.text(_warning), findsNothing);
      expect(stub.calls.single, startsWith('put 5 14'));
    });

    testWidgets('Issue 164: Finalize asks for an answer emptied in a field '
        'that still has the focus', (tester) async {
      final stub = await _pump(tester, evidence: evidence);
      await _empty(tester);
      await tester.tap(find.text('Finalize'));
      await tester.pumpAndSettle();
      expect(find.text(_warning), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(stub.calls.first, 'clear 5 14');
    });

    testWidgets('Issue 164: cancelling keeps what was typed after the '
        'question opened', (tester) async {
      final stub = await _pump(tester, evidence: evidence);
      await _clear(tester);
      expect(find.text(_warning), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Sharp');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_shown(tester), 'Sharp');
      expect(stub.calls.where((c) => c.startsWith('clear')), isEmpty);
    });

    testWidgets('Issue 164: cancelling with nothing typed puts the saved '
        'answer back', (tester) async {
      final stub = await _pump(tester, evidence: evidence);
      await _clear(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_shown(tester), 'Clean');
      expect(stub.calls, isEmpty);
    });
  });
}
