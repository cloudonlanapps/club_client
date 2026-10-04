import 'package:cl_club_evaluation/src/models/evaluation_answer_adapter.dart';
import 'package:cl_club_evaluation/src/models/evaluation_layout_adapter.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

const sdk.EvaluationTemplateItem _info = sdk.EvaluationInfoItem(
  id: 1,
  markdown: 'Read me',
);
const sdk.EvaluationTemplateItem _rating = sdk.EvaluationRatingItem(
  id: 2,
  question: 'Effort',
  rateType: sdk.EvaluationRateType.stars,
  rateMin: 1,
  rateMax: 5,
);
const sdk.EvaluationTemplateItem _qa = sdk.EvaluationQaItem(
  id: 3,
  question: 'Next',
);

const EvaluationItemValue _yesNo = EvaluationItemValue(
  id: 4,
  kind: EvaluationItemKind.yesNo,
  text: 'Stops',
);
const EvaluationItemValue _multi = EvaluationItemValue(
  id: 5,
  kind: EvaluationItemKind.multipleChoice,
  text: 'Areas',
  choices: [EvaluationChoice(value: 'edges', text: 'Edges')],
);

void main() {
  group('Issue 173: EvaluationLayoutAdapter', () {
    const ids = <sdk.EvaluationLayoutEntry<int>>[
      sdk.EvaluationLayoutItem(1),
      sdk.EvaluationLayoutSection('Skating', [2, 3]),
    ];

    test('Issue 173: a template read lays its items out by id', () {
      final layout = EvaluationLayoutAdapter.fromTemplate(ids, const [
        _info,
        _rating,
        _qa,
      ]);
      expect(layout, hasLength(2));
      expect(layout.first.item!.text, 'Read me');
      expect(layout.last.sectionTitle, 'Skating');
      expect(layout.last.sectionItems.map((i) => i.id), [2, 3]);
    });

    test('Issue 173: ids missing from the items are dropped', () {
      final layout = EvaluationLayoutAdapter.fromTemplate(ids, const [_rating]);
      expect(layout.single.sectionItems.single.id, 2);
    });

    test('Issue 173: the form layout goes back as ids and as inline items', () {
      final layout = EvaluationLayoutAdapter.fromTemplate(ids, const [
        _info,
        _rating,
        _qa,
      ]);
      expect(EvaluationLayoutAdapter.toIdLayout(layout), ids);
      final inline = EvaluationLayoutAdapter.toCreateLayout(layout);
      expect(inline.first, const sdk.EvaluationLayoutItem(_info));
      expect(
        inline.last,
        const sdk.EvaluationLayoutSection('Skating', [_rating, _qa]),
      );
    });
  });

  group('Issue 173: EvaluationAnswerAdapter', () {
    test('Issue 173: SDK answers become answer values by item id', () {
      final values = EvaluationAnswerAdapter.toValues(const [
        sdk.EvaluationAnswer(itemId: 4, valueNum: 1, coachNote: 'Good'),
        sdk.EvaluationAnswer(itemId: 5, choices: ['edges']),
      ]);
      expect(values, {
        4: const EvaluationAnswerValue(valueNum: 1, coachNote: 'Good'),
        5: const EvaluationAnswerValue(choices: ['edges']),
      });
    });

    test('Issue 173: yes / no is written as 1 / 0', () {
      final yes = EvaluationAnswerAdapter.toInput(
        _yesNo,
        const EvaluationAnswerValue(valueNum: 1),
      );
      final no = EvaluationAnswerAdapter.toInput(
        _yesNo,
        const EvaluationAnswerValue(valueNum: 0, coachNote: 'Work on it'),
      );
      expect(yes, const sdk.EvaluationAnswerInput.yesNo(yes: true));
      expect(
        no,
        const sdk.EvaluationAnswerInput.yesNo(
          yes: false,
          coachNote: 'Work on it',
        ),
      );
    });

    test('Issue 173: each kind sends its own field; a note alone is kept', () {
      expect(
        EvaluationAnswerAdapter.toInput(
          _multi,
          const EvaluationAnswerValue(choices: ['edges']),
        ),
        const sdk.EvaluationAnswerInput(choices: ['edges']),
      );
      expect(
        EvaluationAnswerAdapter.toInput(
          _multi,
          const EvaluationAnswerValue(coachNote: 'Keep going'),
        ),
        const sdk.EvaluationAnswerInput(coachNote: 'Keep going'),
      );
    });

    test('Issue 173: an empty answer is no input (it is cleared)', () {
      expect(
        EvaluationAnswerAdapter.toInput(
          _multi,
          const EvaluationAnswerValue(coachNote: '  '),
        ),
        isNull,
      );
    });
  });
}
