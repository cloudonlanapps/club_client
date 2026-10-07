import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/evaluation/item_form/evaluation_item_form_fields.dart'
    show EvaluationItemFormFields;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

typedef _F = EvaluationItemFormFields;

Future<GlobalKey<EvaluationItemFormState>> _pump(
  WidgetTester tester,
  EvaluationItemValue item, {
  bool readOnly = false,
}) async {
  await tallSurface(tester);
  final key = GlobalKey<EvaluationItemFormState>();
  await tester.pumpWidget(
    wrapEvaluation(
      EvaluationItemForm(
        key: key,
        kind: item.kind,
        initialValues: EvaluationItemFormValues.fromItem(item),
        readOnly: readOnly,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

void main() {
  group('Issue 173: EvaluationItemForm', () {
    testWidgets('Issue 173: a read-only form disables its fields and '
        'ignores taps', (tester) async {
      final key = await _pump(tester, yesNoItem, readOnly: true);
      final form = tester.widget<ShadForm>(find.byType(ShadForm));
      expect(form.enabled, isFalse);
      await tester.tap(find.text('Required'));
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 173: an empty question fails with a field error', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        EvaluationItemValue.newOfKind(EvaluationItemKind.number),
      );
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Enter the question.'), findsOneWidget);
    });

    testWidgets('Issue 173: a valid range rating returns whole numbers', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        const EvaluationItemValue(
          kind: EvaluationItemKind.rating,
          text: 'Edges',
          scale: EvaluationRatingScale.range(min: 1, max: 10),
        ),
      );
      final values = key.currentState!.validate();
      expect(values, isNotNull);
      expect(values![_F.textId], 'Edges');
      expect(values[_F.ratingStyleId], EvaluationRatingStyle.range);
      expect(values[_F.rateMinId], 1);
      expect(values[_F.rateMaxId], 10);
      final item = EvaluationItemFormValues.toItem(
        values,
        kind: EvaluationItemKind.rating,
      );
      expect(item.scale, const EvaluationRatingScale.range(min: 1, max: 10));
    });

    testWidgets('Issue 173: min above max is refused', (tester) async {
      final key = await _pump(
        tester,
        const EvaluationItemValue(
          kind: EvaluationItemKind.rating,
          text: 'Edges',
          scale: EvaluationRatingScale.range(min: 1, max: 10),
        ),
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller.text == '1',
        ),
        '12',
      );
      await tester.pump();
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(
        find.text('The highest value must be above the lowest.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 173: choices return values derived from labels', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        const EvaluationItemValue(
          kind: EvaluationItemKind.singleChoice,
          text: 'Best stop',
          choices: [
            EvaluationChoice(value: 'x', text: 'Hockey stop'),
            EvaluationChoice(value: 'y', text: 'Snow plough'),
          ],
        ),
      );
      final values = key.currentState!.validate()!;
      expect(values[_F.choicesId], const [
        EvaluationChoice(value: 'hockey_stop', text: 'Hockey stop'),
        EvaluationChoice(value: 'snow_plough', text: 'Snow plough'),
      ]);
    });

    testWidgets('Issue 173: a choice question without choices fails', (
      tester,
    ) async {
      final key = await _pump(
        tester,
        const EvaluationItemValue(
          kind: EvaluationItemKind.multipleChoice,
          text: 'Strong areas',
        ),
      );
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text('Add at least one choice.'), findsOneWidget);
    });

    testWidgets('Issue 173: the note rule keeps only offered answers', (
      tester,
    ) async {
      final key = await _pump(tester, levelsItem);
      expect(find.text('Require a coach note for'), findsOneWidget);
      final values = key.currentState!.validate()!;
      expect(values[_F.requireCommentForId], [1]);
      expect(values[_F.levelsId], [
        'Needs work',
        'Developing',
        'Good',
        'Excellent',
      ]);
      final item = EvaluationItemFormValues.toItem(
        values,
        kind: EvaluationItemKind.rating,
        id: 1,
      );
      expect(item, levelsItem);
    });

    testWidgets('Issue 173: turning the comment area off drops the rule', (
      tester,
    ) async {
      final key = await _pump(tester, levelsItem);
      await tester.tap(find.text('Comment area'));
      await tester.pumpAndSettle();
      expect(find.text('Require a coach note for'), findsNothing);
      final values = key.currentState!.validate()!;
      expect(values[_F.showCommentAreaId], isFalse);
      expect(values[_F.requireCommentForId], isEmpty);
    });

    testWidgets('Issue 173: a Q & A has no comment area', (tester) async {
      await _pump(tester, qaItem);
      expect(find.text('Comment area'), findsNothing);
      expect(find.text('Allow evidence'), findsOneWidget);
    });

    testWidgets('Issue 173: an info text edits markdown only', (
      tester,
    ) async {
      final key = await _pump(tester, infoItem);
      expect(find.text('Required'), findsNothing);
      expect(find.text('Allow evidence'), findsNothing);
      final values = key.currentState!.validate()!;
      expect(values[_F.textId], 'Rate what you saw this term.');
    });

    testWidgets('Issue 173: isDirty follows edits', (tester) async {
      final key = await _pump(tester, qaItem);
      expect(key.currentState!.isDirty, isFalse);
      await tester.enterText(
        find.byType(EditableText).first,
        'What to work on',
      );
      await tester.pump();
      expect(key.currentState!.isDirty, isTrue);
    });
  });
}
