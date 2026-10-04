import 'package:cl_club_evaluation/src/models/evaluation_item_adapter.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

/// One SDK item of every variant and scale, as the server returns them.
const List<sdk.EvaluationTemplateItem> _everyVariant = [
  sdk.EvaluationRatingItem(
    id: 1,
    question: 'Effort',
    isRequired: true,
    allowEvidence: true,
    showCommentArea: true,
    requireCommentFor: [1],
    rateType: sdk.EvaluationRateType.stars,
    rateMin: 1,
    rateMax: 5,
  ),
  sdk.EvaluationRatingItem(
    id: 2,
    question: 'Balance',
    rateMin: 1,
    rateMax: 10,
    originItemId: 40,
  ),
  sdk.EvaluationRatingItem(
    id: 3,
    question: 'Forward stride',
    isPrivate: true,
    showCommentArea: true,
    requireCommentFor: [1, 2],
    rateValues: [
      sdk.EvaluationRateLevel(value: 1, text: 'Needs work'),
      sdk.EvaluationRateLevel(value: 2, text: 'Good'),
    ],
  ),
  sdk.EvaluationYesNoItem(
    id: 4,
    question: 'Stops on both sides',
    showCommentArea: true,
    requireCommentFor: [false],
    labelTrue: 'Always',
    labelFalse: 'Not yet',
  ),
  sdk.EvaluationSingleChoiceItem(
    id: 5,
    question: 'Position',
    showCommentArea: true,
    requireCommentFor: ['goalie'],
    choices: [
      sdk.EvaluationChoice(value: 'forward', text: 'Forward'),
      sdk.EvaluationChoice(value: 'goalie', text: 'Goalie'),
    ],
  ),
  sdk.EvaluationMultipleChoiceItem(
    id: 6,
    question: 'Strong areas',
    allowEvidence: true,
    choices: [
      sdk.EvaluationChoice(value: 'edges', text: 'Edges'),
      sdk.EvaluationChoice(value: 'crossovers', text: 'Crossovers'),
    ],
  ),
  sdk.EvaluationNumberItem(
    id: 7,
    question: 'Laps',
    showCommentArea: true,
    requireCommentFor: [0],
  ),
  sdk.EvaluationQaItem(id: 8, question: 'What next', isRequired: true),
  sdk.EvaluationInfoItem(id: 9, markdown: 'Rate **this term**.'),
];

void main() {
  group('Issue 173: EvaluationItemAdapter', () {
    test('Issue 173: every variant round-trips SDK → form value → SDK', () {
      for (final item in _everyVariant) {
        final value = EvaluationItemAdapter.toValue(item);
        expect(EvaluationItemAdapter.toSdk(value), item, reason: '$item');
      }
    });

    test('Issue 173: rating scales map to stars, range and levels', () {
      final scales = [
        for (final item in _everyVariant.take(3))
          EvaluationItemAdapter.toValue(item).scale,
      ];
      expect(scales, const [
        EvaluationRatingScale.stars(),
        EvaluationRatingScale.range(min: 1, max: 10),
        EvaluationRatingScale.levels(['Needs work', 'Good']),
      ]);
    });

    test('Issue 173: requireCommentFor keeps each kind its own type', () {
      final values = {
        for (final item in _everyVariant)
          item.type: EvaluationItemAdapter.toValue(item).requireCommentFor,
      };
      expect(values[sdk.EvaluationItemType.rating], [1, 2]);
      expect(values[sdk.EvaluationItemType.yesNo], [false]);
      expect(values[sdk.EvaluationItemType.singleChoice], ['goalie']);
      expect(values[sdk.EvaluationItemType.number], [0]);
    });

    test('Issue 173: kinds, origin and info text carry over', () {
      final balance = EvaluationItemAdapter.toValue(_everyVariant[1]);
      final info = EvaluationItemAdapter.toValue(_everyVariant.last);
      expect(balance.originItemId, 40);
      expect(info.kind, EvaluationItemKind.info);
      expect(info.text, 'Rate **this term**.');
    });

    test('Issue 173: copyOf makes a new copy pointing at the origin', () {
      final copy = EvaluationItemAdapter.copyOf(_everyVariant[4]);
      final copyOfCopy = EvaluationItemAdapter.copyOf(_everyVariant[1]);
      expect(copy.id, isNull);
      expect(copy.originItemId, 5);
      expect(copy.choices.map((c) => c.value), ['forward', 'goalie']);
      expect(copyOfCopy.originItemId, 40);
    });

    test('Issue 173: a relabelled copy keeps its origin choice values by '
        'position, and its coach-note rule follows them', () {
      final before = EvaluationItemAdapter.copyOf(_everyVariant[4]);
      // The item form derives values from the new labels and drops the
      // origin.
      const edited = EvaluationItemValue(
        kind: EvaluationItemKind.singleChoice,
        text: 'Position',
        showCommentArea: true,
        requireCommentFor: ['keeper'],
        choices: [
          EvaluationChoice(value: 'skater', text: 'Skater'),
          EvaluationChoice(value: 'keeper', text: 'Keeper'),
          EvaluationChoice(value: 'coach', text: 'Coach'),
        ],
      );
      final kept = EvaluationItemAdapter.keepOrigin(before, edited);
      expect(kept.originItemId, 5);
      expect(kept.choices, const [
        EvaluationChoice(value: 'forward', text: 'Skater'),
        EvaluationChoice(value: 'goalie', text: 'Keeper'),
        EvaluationChoice(value: 'coach', text: 'Coach'),
      ]);
      expect(kept.requireCommentFor, ['goalie']);
    });

    test('Issue 173: an item that is no copy is left as edited', () {
      final before = EvaluationItemAdapter.toValue(_everyVariant[5]);
      final edited = before.copyWith(
        choices: const [EvaluationChoice(value: 'speed', text: 'Speed')],
      );
      expect(EvaluationItemAdapter.keepOrigin(before, edited), edited);
    });
  });
}
