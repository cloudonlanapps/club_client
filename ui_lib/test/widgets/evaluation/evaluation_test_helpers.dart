import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Hosts [child] in a scrollable shadcn app.
Widget wrapEvaluation(Widget child) => ShadApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

/// A tall surface so long forms lay out without scrolling.
Future<void> tallSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// A rating on labelled levels.
const EvaluationItemValue levelsItem = EvaluationItemValue(
  id: 1,
  kind: EvaluationItemKind.rating,
  text: 'Forward stride',
  isRequired: true,
  showCommentArea: true,
  requireCommentFor: [1],
  scale: EvaluationRatingScale.levels([
    'Needs work',
    'Developing',
    'Good',
    'Excellent',
  ]),
);

/// A yes / no question.
const EvaluationItemValue yesNoItem = EvaluationItemValue(
  id: 2,
  kind: EvaluationItemKind.yesNo,
  text: 'Stops on both sides',
  allowEvidence: true,
);

/// A required Q & A.
const EvaluationItemValue qaItem = EvaluationItemValue(
  id: 3,
  kind: EvaluationItemKind.qa,
  text: 'What to work on next',
  isRequired: true,
);

/// An info text.
const EvaluationItemValue infoItem = EvaluationItemValue(
  id: 4,
  kind: EvaluationItemKind.info,
  text: 'Rate what you saw this term.',
);

/// A multiple-choice question.
const EvaluationItemValue multiItem = EvaluationItemValue(
  id: 5,
  kind: EvaluationItemKind.multipleChoice,
  text: 'Strong areas',
  choices: [
    EvaluationChoice(value: 'edges', text: 'Edges'),
    EvaluationChoice(value: 'crossovers', text: 'Crossovers'),
  ],
);

/// A layout: an info text, a section of two, then a Q & A.
const List<EvaluationLayoutEntry> sampleLayout = [
  EvaluationLayoutEntry.item(infoItem),
  EvaluationLayoutEntry.section(
    title: 'Skating',
    items: [levelsItem, yesNoItem],
  ),
  EvaluationLayoutEntry.item(qaItem),
];
