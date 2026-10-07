import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_level_buttons.dart'
    show EvaluationLevelButtons;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_range_input.dart'
    show EvaluationRangeInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_star_input.dart'
    show EvaluationStarInput;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

void main() {
  group('Issue 173: EvaluationReadBody', () {
    testWidgets('Issue 173: shows answers, notes and gaps without inputs', (
      tester,
    ) async {
      await tallSurface(tester);
      final evidence = <int>[];
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationReadBody(
            layout: const [
              ...sampleLayout,
              EvaluationLayoutEntry.item(multiItem),
            ],
            answers: const {
              1: EvaluationAnswerValue(valueNum: 3, coachNote: 'Longer push'),
              2: EvaluationAnswerValue(valueNum: 0),
              5: EvaluationAnswerValue(choices: ['edges', 'crossovers']),
            },
            evidenceBuilder: (id) {
              evidence.add(id);
              return Text('evidence $id');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skating'), findsOneWidget);
      expect(find.text('Forward stride'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Edges, Crossovers'), findsOneWidget);
      expect(find.text('Coach note'), findsOneWidget);
      expect(find.text('Longer push'), findsOneWidget);
      // The Q & A was left unanswered.
      expect(find.text('Not answered'), findsOneWidget);
      expect(find.text('evidence 2'), findsOneWidget);
      expect(evidence.toSet(), {2});
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(EvaluationLevelButtons), findsNothing);
    });

    testWidgets('Issue 173: stars read as filled stars', (tester) async {
      await tester.pumpWidget(
        wrapEvaluation(
          const EvaluationReadBody(
            layout: [
              EvaluationLayoutEntry.item(
                EvaluationItemValue(
                  id: 7,
                  kind: EvaluationItemKind.rating,
                  text: 'Effort',
                  scale: EvaluationRatingScale.stars(),
                ),
              ),
            ],
            answers: {7: EvaluationAnswerValue(valueNum: 4)},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EvaluationStarInput), findsOneWidget);
      expect(find.text('4 / 5'), findsOneWidget);
    });

    Future<void> pumpRange(WidgetTester tester, int max) => tester.pumpWidget(
      wrapEvaluation(
        EvaluationReadBody(
          layout: [
            EvaluationLayoutEntry.item(
              EvaluationItemValue(
                id: 8,
                kind: EvaluationItemKind.rating,
                text: 'Speed',
                scale: EvaluationRatingScale.range(min: 1, max: max),
              ),
            ),
          ],
          answers: const {8: EvaluationAnswerValue(valueNum: 7)},
        ),
      ),
    );

    testWidgets('Issue 173: a range of up to ten reads as its buttons, '
        'filled up to the value', (tester) async {
      await pumpRange(tester, 10);
      await tester.pumpAndSettle();
      final input = tester.widget<EvaluationRangeInput>(
        find.byType(EvaluationRangeInput),
      );
      expect(input.value, 7);
      expect(input.enabled, isFalse);
      expect(find.text('7 / 10'), findsOneWidget);
    });

    testWidgets('Issue 173: a longer range reads as text', (tester) async {
      await pumpRange(tester, 20);
      await tester.pumpAndSettle();
      expect(find.byType(EvaluationRangeInput), findsNothing);
      expect(find.text('7 / 20'), findsOneWidget);
    });
  });
}
