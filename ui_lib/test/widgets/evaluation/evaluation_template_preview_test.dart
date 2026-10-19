import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

// A template being designed: no item has an id yet. One item of each of
// the seven kinds, the rating in all three styles; loose items, a section,
// and the closing Q & As.
const EvaluationItemValue _intro = EvaluationItemValue(
  kind: EvaluationItemKind.info,
  text: 'Rate what you saw this term.',
);
const EvaluationItemValue _stars = EvaluationItemValue(
  kind: EvaluationItemKind.rating,
  text: 'Balance',
  scale: EvaluationRatingScale.stars(),
);
const EvaluationItemValue _range = EvaluationItemValue(
  kind: EvaluationItemKind.rating,
  text: 'Speed',
  scale: EvaluationRatingScale.range(min: 1, max: 10),
);
const EvaluationItemValue _levels = EvaluationItemValue(
  kind: EvaluationItemKind.rating,
  text: 'Forward stride',
  showCommentArea: true,
  scale: EvaluationRatingScale.levels(['Needs work', 'Good']),
);
const EvaluationItemValue _yesNo = EvaluationItemValue(
  kind: EvaluationItemKind.yesNo,
  text: 'Stops on both sides',
  allowEvidence: true,
);
const EvaluationItemValue _single = EvaluationItemValue(
  kind: EvaluationItemKind.singleChoice,
  text: 'Best position',
  choices: [
    EvaluationChoice(value: 'f', text: 'Forward'),
    EvaluationChoice(value: 'd', text: 'Defence'),
  ],
);
const EvaluationItemValue _multi = EvaluationItemValue(
  kind: EvaluationItemKind.multipleChoice,
  text: 'Strong areas',
  isPrivate: true,
  choices: [
    EvaluationChoice(value: 'e', text: 'Edges'),
    EvaluationChoice(value: 'c', text: 'Crossovers'),
  ],
);
const EvaluationItemValue _number = EvaluationItemValue(
  kind: EvaluationItemKind.number,
  text: 'Laps in a minute',
);
const EvaluationItemValue _qa = EvaluationItemValue(
  kind: EvaluationItemKind.qa,
  text: 'What to work on next',
);

const List<EvaluationLayoutEntry> _layout = [
  EvaluationLayoutEntry.item(_intro),
  EvaluationLayoutEntry.item(_stars),
  EvaluationLayoutEntry.section(
    title: 'Skating',
    items: [_range, _levels, _yesNo],
  ),
  EvaluationLayoutEntry.section(
    title: 'Game',
    items: [_single, _multi, _number],
  ),
  EvaluationLayoutEntry.item(_qa),
];

Future<void> _pump(
  WidgetTester tester, [
  List<EvaluationLayoutEntry> layout = _layout,
]) async {
  await tallSurface(tester);
  await tester.pumpWidget(
    wrapEvaluation(EvaluationTemplatePreview(layout: layout)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 28: EvaluationTemplatePreview', () {
    testWidgets('Issue 28: shows every item of an unsaved template in '
        'layout order, sections titled, the closing Q & A last', (
      tester,
    ) async {
      await _pump(tester);
      expect(tester.takeException(), isNull);
      final order = [
        'Rate what you saw this term.',
        'Balance',
        'Skating',
        'Speed',
        'Forward stride',
        'Stops on both sides',
        'Game',
        'Best position',
        'Strong areas',
        'Laps in a minute',
        'What to work on next',
      ];
      final tops = [
        for (final text in order) tester.getTopLeft(find.text(text)).dy,
      ];
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]), reason: order[i]);
      }
    });

    testWidgets('Issue 28: each kind shows its input, the comment area '
        'and an evidence placeholder where the item has them', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Needs work'), findsOneWidget);
      expect(find.text('Forward'), findsOneWidget);
      expect(find.text('Crossovers'), findsOneWidget);
      expect(find.text('Coach note'), findsOneWidget);
      expect(find.byType(ShadCheckbox), findsNWidgets(2));
      expect(find.text('Evidence: images, videos and PDFs'), findsOneWidget);
    });

    testWidgets('Issue 28: nothing in it can be answered', (tester) async {
      await _pump(tester);
      expect(find.byType(ShadButton), findsWidgets);
      expect(find.byType(ShadInput), findsWidgets);
      for (final button in tester.widgetList<ShadButton>(
        find.byType(ShadButton),
      )) {
        expect(button.enabled, isFalse);
      }
      for (final box in tester.widgetList<ShadCheckbox>(
        find.byType(ShadCheckbox),
      )) {
        expect(box.enabled, isFalse);
      }
      for (final input in tester.widgetList<ShadInput>(
        find.byType(ShadInput),
      )) {
        expect(input.enabled, isFalse);
      }
    });

    testWidgets('Issue 28: a private item is greyed', (tester) async {
      await _pump(tester);
      final shade = find.ancestor(
        of: find.text('Strong areas'),
        matching: find.byType(Opacity),
      );
      expect(shade, findsOneWidget);
      expect(
        tester.widget<Opacity>(shade).opacity,
        EvaluationSpacing.privateOpacity,
      );
      expect(
        find.ancestor(
          of: find.text('Laps in a minute'),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 28: follows a changed layout', (tester) async {
      await _pump(tester, const [EvaluationLayoutEntry.item(_stars)]);
      expect(find.text('Balance'), findsOneWidget);
      await _pump(tester, const [EvaluationLayoutEntry.item(_number)]);
      expect(find.text('Balance'), findsNothing);
      expect(find.text('Laps in a minute'), findsOneWidget);
    });

    testWidgets('Issue 28: a template with no items says how to begin', (
      tester,
    ) async {
      await _pump(tester, const []);
      expect(find.text('Add a question to see it here.'), findsOneWidget);
    });

    test('Issue 28: items without an id get distinct ids below zero; '
        'saved ids are kept', () {
      final layout = EvaluationTemplatePreview.withIds([
        const EvaluationLayoutEntry.item(_stars),
        EvaluationLayoutEntry.section(
          title: 'Skating',
          items: [
            _range,
            _levels.copyWith(id: () => 7),
          ],
        ),
      ]);
      final ids = [
        for (final item in EvaluationLayoutEntry.flatten(layout)) item.id,
      ];
      expect(ids, [-1, -2, 7]);
    });
  });
}
