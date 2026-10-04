import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/models/evaluation_layout_position.dart';
import 'package:ui_lib/src/utils/evaluation_layout_ops.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

typedef _P = EvaluationLayoutPosition;

void main() {
  group('Issue 173: EvaluationLayoutOps', () {
    test('Issue 173: positions follow the outline order', () {
      expect(EvaluationLayoutOps.positions(sampleLayout), const [
        _P(entry: 0),
        _P(entry: 1),
        _P(entry: 1, child: 0),
        _P(entry: 1, child: 1),
        _P(entry: 2),
      ]);
    });

    test('Issue 173: an item moving down onto a section enters it', () {
      final moved = EvaluationLayoutOps.move(
        sampleLayout,
        const _P(entry: 0),
        1,
      );
      expect(moved, const [
        EvaluationLayoutEntry.section(
          title: 'Skating',
          items: [infoItem, levelsItem, yesNoItem],
        ),
        EvaluationLayoutEntry.item(qaItem),
      ]);
    });

    test('Issue 173: an item moving up onto a section joins its end', () {
      final moved = EvaluationLayoutOps.move(
        sampleLayout,
        const _P(entry: 2),
        -1,
      );
      expect(moved![1].sectionItems, const [levelsItem, yesNoItem, qaItem]);
      expect(moved, hasLength(2));
    });

    test('Issue 173: the first item of a section moves out above it', () {
      final moved = EvaluationLayoutOps.move(
        sampleLayout,
        const _P(entry: 1, child: 0),
        -1,
      );
      expect(moved, const [
        EvaluationLayoutEntry.item(infoItem),
        EvaluationLayoutEntry.item(levelsItem),
        EvaluationLayoutEntry.section(title: 'Skating', items: [yesNoItem]),
        EvaluationLayoutEntry.item(qaItem),
      ]);
    });

    test('Issue 173: the last item of a section moves out below it', () {
      final moved = EvaluationLayoutOps.move(
        sampleLayout,
        const _P(entry: 1, child: 1),
        1,
      );
      expect(moved![2], const EvaluationLayoutEntry.item(yesNoItem));
    });

    test('Issue 173: items swap inside a section', () {
      final moved = EvaluationLayoutOps.move(
        sampleLayout,
        const _P(entry: 1, child: 0),
        1,
      );
      expect(moved![1].sectionItems, const [yesNoItem, levelsItem]);
    });

    test('Issue 173: a section moves as a block', () {
      final moved = EvaluationLayoutOps.move(
        sampleLayout,
        const _P(entry: 1),
        -1,
      );
      expect(moved![0].isSection, isTrue);
      expect(moved[1], const EvaluationLayoutEntry.item(infoItem));
    });

    test('Issue 173: nothing moves past either end', () {
      expect(
        EvaluationLayoutOps.move(sampleLayout, const _P(entry: 0), -1),
        isNull,
      );
      expect(
        EvaluationLayoutOps.move(sampleLayout, const _P(entry: 2), 1),
        isNull,
      );
    });

    test('Issue 173: removing a section keeps its items in place', () {
      final removed = EvaluationLayoutOps.remove(
        sampleLayout,
        const _P(entry: 1),
      );
      expect(removed, const [
        EvaluationLayoutEntry.item(infoItem),
        EvaluationLayoutEntry.item(levelsItem),
        EvaluationLayoutEntry.item(yesNoItem),
        EvaluationLayoutEntry.item(qaItem),
      ]);
    });

    test('Issue 173: removing an item in a section', () {
      final removed = EvaluationLayoutOps.remove(
        sampleLayout,
        const _P(entry: 1, child: 1),
      );
      expect(removed[1].sectionItems, const [levelsItem]);
    });

    test('Issue 173: replace, append and rename', () {
      const renamed = EvaluationItemValue(
        kind: EvaluationItemKind.qa,
        text: 'Next steps',
      );
      expect(
        EvaluationLayoutOps.replaceItem(
          sampleLayout,
          const _P(entry: 1, child: 0),
          renamed,
        )[1].sectionItems.first,
        renamed,
      );
      expect(
        EvaluationLayoutOps.appendItem(
          sampleLayout,
          renamed,
          section: 1,
        )[1].sectionItems.last,
        renamed,
      );
      expect(
        EvaluationLayoutOps.appendItem(sampleLayout, renamed).last,
        const EvaluationLayoutEntry.item(renamed),
      );
      expect(
        EvaluationLayoutOps.renameSection(
          sampleLayout,
          1,
          'Edges',
        )[1].sectionTitle,
        'Edges',
      );
    });

    test('Issue 173: flatten lists items in order', () {
      expect(EvaluationLayoutEntry.flatten(sampleLayout), const [
        infoItem,
        levelsItem,
        yesNoItem,
        qaItem,
      ]);
    });
  });
}
