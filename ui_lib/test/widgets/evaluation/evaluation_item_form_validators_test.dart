import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/utils/evaluation_answer_rules.dart';
import 'package:ui_lib/src/utils/evaluation_choice_values.dart';
import 'package:ui_lib/src/widgets/evaluation/item_form/evaluation_item_form_validators.dart'
    show EvaluationItemFormValidators;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

void main() {
  group('Issue 173: EvaluationItemFormValidators', () {
    test('Issue 173: the question is required', () {
      expect(EvaluationItemFormValidators.question('  '), isNotNull);
      expect(EvaluationItemFormValidators.question('Edges'), isNull);
    });

    test('Issue 173: an info text is required', () {
      expect(EvaluationItemFormValidators.infoText(''), isNotNull);
      expect(EvaluationItemFormValidators.infoText('Read this'), isNull);
    });

    test('Issue 173: the lowest value is a whole number', () {
      expect(EvaluationItemFormValidators.rateMin('x'), isNotNull);
      expect(EvaluationItemFormValidators.rateMin('1.5'), isNotNull);
      expect(EvaluationItemFormValidators.rateMin('0'), isNull);
    });

    test('Issue 173: the highest value is above the lowest', () {
      expect(EvaluationItemFormValidators.rateMax('5', '5'), isNotNull);
      expect(EvaluationItemFormValidators.rateMax('3', '5'), isNotNull);
      expect(EvaluationItemFormValidators.rateMax('x', '1'), isNotNull);
      expect(EvaluationItemFormValidators.rateMax('10', '1'), isNull);
    });

    test('Issue 173: levels are non-empty, labelled and distinct', () {
      expect(EvaluationItemFormValidators.levels(null), isNotNull);
      expect(EvaluationItemFormValidators.levels(const []), isNotNull);
      expect(
        EvaluationItemFormValidators.levels(const ['Good', ' ']),
        isNotNull,
      );
      expect(
        EvaluationItemFormValidators.levels(const ['Good', 'good ']),
        isNotNull,
      );
      expect(
        EvaluationItemFormValidators.levels(const ['Developing', 'Good']),
        isNull,
      );
    });

    test('Issue 173: choices need one label and distinct derived values', () {
      expect(EvaluationItemFormValidators.choices(const []), isNotNull);
      expect(EvaluationItemFormValidators.choices(const ['']), isNotNull);
      expect(EvaluationItemFormValidators.choices(const ['?!']), isNotNull);
      // "Left edge" and "left-edge" derive the same value.
      expect(
        EvaluationItemFormValidators.choices(const ['Left edge', 'left-edge']),
        isNotNull,
      );
      expect(
        EvaluationItemFormValidators.choices(const ['Left edge', 'Right edge']),
        isNull,
      );
    });

    test('Issue 173: a required note needs the comment area', () {
      expect(
        EvaluationItemFormValidators.requireCommentFor(const [
          1,
        ], showCommentArea: false),
        isNotNull,
      );
      expect(
        EvaluationItemFormValidators.requireCommentFor(const [
          1,
        ], showCommentArea: true),
        isNull,
      );
      expect(
        EvaluationItemFormValidators.requireCommentFor(
          const [],
          showCommentArea: false,
        ),
        isNull,
      );
    });
  });

  group('Issue 173: EvaluationChoiceValues', () {
    test('Issue 173: values derive from labels', () {
      expect(EvaluationChoiceValues.valueFor('Left Edge!'), 'left_edge');
      expect(EvaluationChoiceValues.valueFor('  Crossovers '), 'crossovers');
      expect(EvaluationChoiceValues.fromLabels(const ['A b', 'C']), const [
        EvaluationChoice(value: 'a_b', text: 'A b'),
        EvaluationChoice(value: 'c', text: 'C'),
      ]);
    });
  });

  group('Issue 173: EvaluationAnswerRules', () {
    test('Issue 173: a required question needs an answer', () {
      expect(
        EvaluationAnswerRules.validate(qaItem, const EvaluationAnswerValue()),
        isNotNull,
      );
      expect(
        EvaluationAnswerRules.validate(
          qaItem,
          const EvaluationAnswerValue(valueText: 'Edges'),
        ),
        isNull,
      );
    });

    test('Issue 173: an answer in requireCommentFor needs a coach note', () {
      const needsWork = EvaluationAnswerValue(valueNum: 1);
      expect(EvaluationAnswerRules.noteRequired(levelsItem, needsWork), isTrue);
      expect(EvaluationAnswerRules.validate(levelsItem, needsWork), isNotNull);
      expect(
        EvaluationAnswerRules.validate(
          levelsItem,
          const EvaluationAnswerValue(valueNum: 1, coachNote: 'Bend knees'),
        ),
        isNull,
      );
      expect(
        EvaluationAnswerRules.validate(
          levelsItem,
          const EvaluationAnswerValue(valueNum: 3),
        ),
        isNull,
      );
    });

    test('Issue 173: yes / no rules use true and false', () {
      const item = EvaluationItemValue(
        id: 9,
        kind: EvaluationItemKind.yesNo,
        text: 'Ready',
        showCommentArea: true,
        requireCommentFor: [false],
      );
      expect(
        EvaluationAnswerRules.noteRequired(
          item,
          const EvaluationAnswerValue(valueNum: 0),
        ),
        isTrue,
      );
      expect(
        EvaluationAnswerRules.noteRequired(
          item,
          const EvaluationAnswerValue(valueNum: 1),
        ),
        isFalse,
      );
    });

    test('Issue 173: answer options list values with labels', () {
      expect(EvaluationAnswerRules.answerOptions(levelsItem), [
        (1, 'Needs work'),
        (2, 'Developing'),
        (3, 'Good'),
        (4, 'Excellent'),
      ]);
      expect(EvaluationAnswerRules.answerOptions(yesNoItem), [
        (true, 'Yes'),
        (false, 'No'),
      ]);
      expect(EvaluationAnswerRules.answerOptions(qaItem), isNull);
    });
  });
}
