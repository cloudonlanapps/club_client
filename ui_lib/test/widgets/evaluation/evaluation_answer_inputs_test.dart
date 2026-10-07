import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_coach_note_input.dart'
    show EvaluationCoachNoteInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_level_buttons.dart'
    show EvaluationLevelButtons;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_multiple_choice_input.dart'
    show EvaluationMultipleChoiceInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_number_input.dart'
    show EvaluationNumberInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_range_input.dart'
    show EvaluationRangeInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_single_choice_input.dart'
    show EvaluationSingleChoiceInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_star_input.dart'
    show EvaluationStarInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_star_painter.dart';
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_text_answer_input.dart'
    show EvaluationTextAnswerInput;
import 'package:ui_lib/src/widgets/evaluation/inputs/evaluation_yes_no_input.dart'
    show EvaluationYesNoInput;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

Finder _stars() => find.descendant(
  of: find.byType(EvaluationStarInput),
  matching: find.byType(CustomPaint),
);

bool _filled(WidgetTester tester, int index) =>
    (tester.widget<CustomPaint>(_stars().at(index)).painter!
            as EvaluationStarPainter)
        .filled;

void main() {
  group('Issue 173: EvaluationStarInput', () {
    testWidgets('Issue 173: fills the chosen star and those below it', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationStarInput(min: 1, max: 5, value: 3, onChanged: (_) {}),
        ),
      );
      expect(_stars(), findsNWidgets(5));
      expect(
        [for (var i = 0; i < 5; i++) _filled(tester, i)],
        [
          true,
          true,
          true,
          false,
          false,
        ],
      );
    });

    testWidgets('Issue 173: tapping a star reports its value', (tester) async {
      int? reported = -1;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationStarInput(
            min: 1,
            max: 5,
            value: null,
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(_stars().at(3));
      expect(reported, 4);
    });

    testWidgets('Issue 173: tapping the chosen star clears it', (
      tester,
    ) async {
      int? reported = -1;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationStarInput(
            min: 1,
            max: 5,
            value: 2,
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(_stars().at(1));
      expect(reported, isNull);
    });

    testWidgets('Issue 173: a disabled star input ignores taps', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationStarInput(
            min: 1,
            max: 5,
            value: null,
            enabled: false,
            onChanged: (_) => called = true,
          ),
        ),
      );
      await tester.tap(_stars().at(0));
      expect(called, isFalse);
    });
  });

  group('Issue 173: EvaluationRangeInput', () {
    Future<List<int?>> pumpRange(
      WidgetTester tester, {
      required int max,
      int? value,
      bool enabled = true,
    }) async {
      final reported = <int?>[];
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationRangeInput(
            min: 1,
            max: max,
            value: value,
            enabled: enabled,
            onChanged: reported.add,
          ),
        ),
      );
      return reported;
    }

    bool filled(WidgetTester tester, String label) =>
        tester
            .widget<ShadButton>(find.widgetWithText(ShadButton, label))
            .variant ==
        ShadButtonVariant.primary;

    testWidgets('Issue 173: up to ten values show one button each, filled up '
        'to the chosen value like stars', (tester) async {
      await pumpRange(tester, max: 5, value: 3);
      expect(find.byType(ShadSlider), findsNothing);
      expect(
        [for (var v = 1; v <= 5; v++) filled(tester, '$v')],
        [true, true, true, false, false],
      );
    });

    testWidgets('Issue 173: every value is one tap, the lowest included', (
      tester,
    ) async {
      final reported = await pumpRange(tester, max: 10);
      await tester.tap(find.widgetWithText(ShadButton, '1'));
      await tester.tap(find.widgetWithText(ShadButton, '10'));
      expect(reported, [1, 10]);
    });

    testWidgets('Issue 173: tapping the chosen value clears it', (
      tester,
    ) async {
      final reported = await pumpRange(tester, max: 10, value: 7);
      await tester.tap(find.widgetWithText(ShadButton, '7'));
      expect(reported, [null]);
    });

    testWidgets('Issue 173: more than ten values step with − and +, starting '
        'at the lowest', (tester) async {
      final reported = await pumpRange(tester, max: 20);
      expect(find.byType(ShadSlider), findsNothing);
      expect(find.widgetWithText(ShadButton, '20'), findsNothing);
      expect(find.text('Not rated'), findsOneWidget);
      expect(find.text('Clear'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Increase'));
      expect(reported, [1]);
    });

    testWidgets('Issue 173: the stepper steps from the value and clears', (
      tester,
    ) async {
      final reported = await pumpRange(tester, max: 20, value: 12);
      expect(find.text('12'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Decrease'));
      await tester.tap(find.bySemanticsLabel('Increase'));
      await tester.tap(find.text('Clear'));
      expect(reported, [11, 13, null]);
    });

    testWidgets('Issue 173: the stepper stops at the highest value', (
      tester,
    ) async {
      final reported = await pumpRange(tester, max: 20, value: 20);
      await tester.tap(find.bySemanticsLabel('Increase'));
      expect(reported, isEmpty);
    });

    testWidgets('Issue 173: a disabled range ignores taps', (tester) async {
      final reported = await pumpRange(tester, max: 5, enabled: false);
      await tester.tap(find.widgetWithText(ShadButton, '2'));
      expect(reported, isEmpty);
    });
  });

  group('Issue 173: EvaluationLevelButtons', () {
    const levels = ['Needs work', 'Developing', 'Good', 'Excellent'];

    testWidgets('Issue 173: a level reports its position, 1-based', (
      tester,
    ) async {
      int? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationLevelButtons(
            levels: levels,
            value: null,
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Good'));
      expect(reported, 3);
    });

    testWidgets('Issue 173: tapping the chosen level clears it', (
      tester,
    ) async {
      int? reported = -1;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationLevelButtons(
            levels: levels,
            value: 3,
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Good'));
      expect(reported, isNull);
    });
  });

  group('Issue 173: EvaluationYesNoInput', () {
    testWidgets('Issue 173: Yes reports true', (tester) async {
      bool? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationYesNoInput(value: null, onChanged: (v) => reported = v),
        ),
      );
      await tester.tap(find.text('Yes'));
      expect(reported, isTrue);
    });

    testWidgets('Issue 173: custom labels replace Yes and No', (
      tester,
    ) async {
      bool? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationYesNoInput(
            value: null,
            labelTrue: 'Pass',
            labelFalse: 'Fail',
            onChanged: (v) => reported = v,
          ),
        ),
      );
      expect(find.text('Yes'), findsNothing);
      await tester.tap(find.text('Fail'));
      expect(reported, isFalse);
    });
  });

  group('Issue 173: choice inputs', () {
    const choices = [
      EvaluationChoice(value: 'a', text: 'Alpha'),
      EvaluationChoice(value: 'b', text: 'Beta'),
    ];

    testWidgets('Issue 173: single choice reports the chosen value', (
      tester,
    ) async {
      String? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationSingleChoiceInput(
            choices: choices,
            value: null,
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(reported, 'b');
    });

    testWidgets('Issue 173: single choice clears once answered', (
      tester,
    ) async {
      String? reported = 'x';
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationSingleChoiceInput(
            choices: choices,
            value: 'a',
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Clear'));
      expect(reported, isNull);
    });

    testWidgets('Issue 173: multiple choice keeps choice order', (
      tester,
    ) async {
      List<String>? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationMultipleChoiceInput(
            choices: choices,
            value: const ['b'],
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Alpha'));
      expect(reported, ['a', 'b']);
    });
  });

  group('Issue 173: text inputs', () {
    testWidgets('Issue 173: a number parses, other text reports null', (
      tester,
    ) async {
      final reported = <num?>[];
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationNumberInput(value: null, onChanged: reported.add),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12.5');
      await tester.pump();
      expect(reported.last, 12.5);
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      expect(reported.last, isNull);
      expect(find.text('Enter a number.'), findsOneWidget);
    });

    testWidgets('Issue 173: a number answer says what to enter', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapEvaluation(EvaluationNumberInput(value: null, onChanged: (_) {})),
      );
      expect(find.text('Enter a number'), findsOneWidget);
    });

    testWidgets('Issue 173: a text answer reports text, empty is null', (
      tester,
    ) async {
      final reported = <String?>[];
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationTextAnswerInput(value: null, onChanged: reported.add),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Keep knees bent');
      expect(reported.last, 'Keep knees bent');
      await tester.enterText(find.byType(EditableText), '   ');
      expect(reported.last, isNull);
    });

    testWidgets('Issue 173: the coach note is labelled and reports text', (
      tester,
    ) async {
      String? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationCoachNoteInput(
            value: null,
            onChanged: (v) => reported = v,
          ),
        ),
      );
      expect(find.text('Coach note'), findsOneWidget);
      expect(find.text('The member sees this note.'), findsOneWidget);
      expect(find.text('Add a note for the member'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Good progress');
      expect(reported, 'Good progress');
    });
  });

  group('Issue 173: EvaluationAnswerInput', () {
    testWidgets('Issue 173: picks the input for the item and keeps the note', (
      tester,
    ) async {
      EvaluationAnswerValue? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationAnswerInput(
            item: levelsItem,
            answer: const EvaluationAnswerValue(coachNote: 'n'),
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Good'));
      expect(
        reported,
        const EvaluationAnswerValue(valueNum: 3, coachNote: 'n'),
      );
    });

    testWidgets('Issue 173: yes / no answers are stored as 1 and 0', (
      tester,
    ) async {
      EvaluationAnswerValue? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationAnswerInput(
            item: yesNoItem,
            answer: const EvaluationAnswerValue(),
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('No'));
      expect(reported?.valueNum, 0);
    });

    testWidgets('Issue 173: multiple choice answers fill choices', (
      tester,
    ) async {
      EvaluationAnswerValue? reported;
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationAnswerInput(
            item: multiItem,
            answer: const EvaluationAnswerValue(),
            onChanged: (v) => reported = v,
          ),
        ),
      );
      await tester.tap(find.text('Crossovers'));
      expect(reported?.choices, ['crossovers']);
    });
  });
}
