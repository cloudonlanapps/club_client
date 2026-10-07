import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

class _Host {
  final changes = <(int, EvaluationAnswerValue)>[];
  final evidenceFor = <int>[];
  final key = GlobalKey<EvaluationFillBodyState>();

  Future<void> pump(
    WidgetTester tester, {
    Map<int, EvaluationAnswerValue> answers = const {},
    bool readOnly = false,
    bool validateOnOpen = false,
  }) async {
    await tallSurface(tester);
    await tester.pumpWidget(
      wrapEvaluation(
        EvaluationFillBody(
          key: key,
          layout: sampleLayout,
          initialAnswers: answers,
          readOnly: readOnly,
          validateOnOpen: validateOnOpen,
          onAnswerChanged: (id, answer) => changes.add((id, answer)),
          evidenceBuilder: (id) {
            evidenceFor.add(id);
            return Text('evidence $id');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Issue 173: EvaluationFillBody', () {
    testWidgets('Issue 173: renders sections, questions and info text', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      expect(find.text('Skating'), findsOneWidget);
      expect(find.text('Forward stride'), findsOneWidget);
      expect(find.text('Rate what you saw this term.'), findsOneWidget);
      expect(find.text('Coach note'), findsOneWidget);
    });

    testWidgets('Issue 173: validateOnOpen shows the gaps at once', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(
        tester,
        answers: const {1: EvaluationAnswerValue(valueNum: 1)},
        validateOnOpen: true,
      );
      // The Q & A is required and empty; level 1 requires a coach note.
      expect(find.text('An answer is required.'), findsOneWidget);
      expect(
        find.text('A coach note is required for this answer.'),
        findsOneWidget,
      );
      expect(host.changes, isEmpty);
    });

    testWidgets('Issue 173: without validateOnOpen gaps wait for Save', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      expect(find.text('An answer is required.'), findsNothing);
    });

    testWidgets('Issue 173: the evidence slot shows where allowed', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      expect(host.evidenceFor.toSet(), {yesNoItem.id});
      expect(find.text('evidence 2'), findsOneWidget);
    });

    testWidgets('Issue 173: a change reports the item and its answer', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      await tester.tap(find.text('Good'));
      await tester.pump();
      expect(host.changes.single, (
        1,
        const EvaluationAnswerValue(valueNum: 3),
      ));
    });

    testWidgets('Issue 173: validateForSave names required gaps', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      expect(host.key.currentState!.validateForSave(), [1, 3]);
      await tester.pump();
      expect(find.text('An answer is required.'), findsNWidgets(2));
    });

    testWidgets('Issue 173: an answer that requires a note blocks saving', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(
        tester,
        answers: const {
          1: EvaluationAnswerValue(valueNum: 1),
          3: EvaluationAnswerValue(valueText: 'Edges'),
        },
      );
      expect(host.key.currentState!.validateForSave(), [1]);
      await tester.pump();
      expect(
        find.text('A coach note is required for this answer.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(EditableText).first, 'Bend knees');
      await tester.pump();
      expect(host.key.currentState!.validateForSave(), isEmpty);
      expect(
        host.changes.last,
        (1, const EvaluationAnswerValue(valueNum: 1, coachNote: 'Bend knees')),
      );
    });

    testWidgets('Issue 173: read-only ignores input', (tester) async {
      final host = _Host();
      await host.pump(tester, readOnly: true);
      await tester.tap(find.text('Good'));
      await tester.pump();
      expect(host.changes, isEmpty);
    });

    testWidgets('Issue 173: markIncomplete shows the server gaps', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      host.key.currentState!.markIncomplete(const [3]);
      await tester.pump();
      expect(find.text('Complete this answer.'), findsOneWidget);
    });
  });
}
