import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

Future<void> _narrow(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('Issue 173: evaluation widgets at phone width', () {
    testWidgets('Issue 173: the layout editor sorts without overflow', (
      tester,
    ) async {
      await _narrow(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationLayoutEditor(
            layout: sampleLayout,
            onLayoutChanged: (_) {},
            onEditItem: (_) async => null,
            onEditSectionTitle: (_) async => null,
          ),
        ),
      );
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 173: the item form lays out without overflow', (
      tester,
    ) async {
      await _narrow(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationItemForm(
            kind: EvaluationItemKind.rating,
            initialValues: EvaluationItemFormValues.fromItem(levelsItem),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 173: the fill form lays out without overflow', (
      tester,
    ) async {
      await _narrow(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationFillBody(
            layout: const [
              ...sampleLayout,
              EvaluationLayoutEntry.item(multiItem),
            ],
            initialAnswers: const {},
            onAnswerChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
