import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

/// The title the closing run no longer carries.
const String _closingTitle = 'Closing remarks';

/// A private Q & A.
const EvaluationItemValue _privateQa = EvaluationItemValue(
  id: 8,
  kind: EvaluationItemKind.qa,
  text: "Coach's private note",
  isPrivate: true,
);

/// A public Q & A.
const EvaluationItemValue _summary = EvaluationItemValue(
  id: 9,
  kind: EvaluationItemKind.qa,
  text: 'Summary',
);

/// A Q & A that is not at the end.
const EvaluationItemValue _earlyQa = EvaluationItemValue(
  id: 10,
  kind: EvaluationItemKind.qa,
  text: 'Early thoughts',
);

/// An early Q & A, a section, then a closing run of two Q & As.
const List<EvaluationLayoutEntry> _closingLayout = [
  EvaluationLayoutEntry.item(_earlyQa),
  EvaluationLayoutEntry.section(title: 'Skating', items: [levelsItem]),
  EvaluationLayoutEntry.item(_summary),
  EvaluationLayoutEntry.item(_privateQa),
];

double _opacityOf(WidgetTester tester, String text) {
  final opacities = tester.widgetList<Opacity>(
    find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
  );
  return opacities.fold(1, (o, w) => o * w.opacity);
}

Finder _cardOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(ShadCard)).first;

/// The closing run of [_closingLayout] shares one card, with no title,
/// holding neither the early Q & A nor the section.
void _expectUntitledClosingCard(WidgetTester tester) {
  expect(find.text(_closingTitle), findsNothing);
  final closing = _cardOf('Summary');
  expect(
    find.descendant(of: closing, matching: find.text("Coach's private note")),
    findsOneWidget,
  );
  for (final text in ['Early thoughts', 'Skating', 'Forward stride']) {
    expect(
      find.descendant(of: closing, matching: find.text(text)),
      findsNothing,
      reason: text,
    );
  }
  expect(tester.widget<ShadCard>(closing).title, isNull);
}

void main() {
  group('Issue 173: the review period ends by today', () {
    final today = DateTime(2026, 9, 15);

    test('Issue 173: start <= end <= today; a one-day period is fine', () {
      final may = DateTime(2026, 5);
      expect(EvaluationPeriodValidators.period(may, may, today: today), isNull);
      expect(
        EvaluationPeriodValidators.period(may, today, today: today),
        isNull,
      );
      expect(
        EvaluationPeriodValidators.period(
          may,
          DateTime(2026, 9, 16),
          today: today,
        ),
        EvaluationPeriodValidators.futureMessage,
      );
      expect(
        EvaluationPeriodValidators.period(today, may, today: today),
        isNotNull,
      );
    });

    testWidgets('Issue 173: the period form says so inline', (tester) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      final now = DateTime.now();
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationPeriodForm(
            key: key,
            initialStart: DateTime(now.year, now.month, now.day),
            initialEnd: DateTime(now.year, now.month, now.day + 3),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), isNull);
      await tester.pump();
      expect(find.text(EvaluationPeriodValidators.futureMessage), findsOne);
    });

    testWidgets('Issue 173: a server refusal shows inline under the period', (
      tester,
    ) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(
        wrapEvaluation(EvaluationPeriodForm(key: key)),
      );
      await tester.pumpAndSettle();
      key.currentState!.showRefusal('Already exists.');
      await tester.pump();
      expect(find.text('Already exists.'), findsOneWidget);
    });
  });

  group('Issue 173: private items in the read-only fill form', () {
    Future<void> pump(WidgetTester tester, {required bool readOnly}) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationFillForm(
            layout: const [
              EvaluationLayoutEntry.item(yesNoItem),
              EvaluationLayoutEntry.item(_privateQa),
            ],
            initialAnswers: const {},
            readOnly: readOnly,
            onAnswerChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Issue 173: read-only greys a private item, not a public '
        'one', (tester) async {
      await pump(tester, readOnly: true);
      expect(_opacityOf(tester, "Coach's private note"), lessThan(1));
      expect(_opacityOf(tester, 'Stops on both sides'), 1);
    });

    testWidgets('Issue 173: the draft editor shows a private item normally', (
      tester,
    ) async {
      await pump(tester, readOnly: false);
      expect(_opacityOf(tester, "Coach's private note"), 1);
    });
  });

  group('Issue 173: the closing run', () {
    test('Issue 173: only a trailing run of top-level Q & As closes', () {
      expect(EvaluationClosingRun.start(_closingLayout), 2);
      expect(EvaluationClosingRun.start(sampleLayout), 2);
      expect(
        EvaluationClosingRun.start(const [
          EvaluationLayoutEntry.item(qaItem),
          EvaluationLayoutEntry.section(title: 'S', items: [qaItem]),
        ]),
        2,
      );
    });

    testWidgets('Issue 173: the read body shows the run as one untitled '
        'card after the rest; an early Q & A stays in place', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          const EvaluationReadBody(layout: _closingLayout, answers: {}),
        ),
      );
      await tester.pumpAndSettle();
      _expectUntitledClosingCard(tester);
      double top(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(top('Early thoughts'), lessThan(top('Skating')));
      expect(top('Skating'), lessThan(top('Summary')));
      expect(top('Summary'), lessThan(top("Coach's private note")));
    });

    testWidgets('Issue 173: the fill form closes the same way', (
      tester,
    ) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationFillForm(
            layout: _closingLayout,
            initialAnswers: const {},
            onAnswerChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectUntitledClosingCard(tester);
      double top(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(top('Skating'), lessThan(top('Summary')));
    });
  });

  group('Issue 173: server refusals inline on the name forms', () {
    testWidgets('Issue 173: RenameForm shows an error the host sets', (
      tester,
    ) async {
      final key = GlobalKey<RenameFormState>();
      await tester.pumpWidget(
        wrapEvaluation(
          RenameForm(key: key, initialValue: 'Skating', label: 'Name'),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.setError('Name taken.');
      await tester.pump();
      expect(find.text('Name taken.'), findsOneWidget);
    });

    testWidgets('Issue 173: the template create form shows a name error the '
        'host sets', (tester) async {
      final key = GlobalKey<EvaluationTemplateCreateFormState>();
      await tallSurface(tester);
      await tester.pumpWidget(
        wrapEvaluation(
          EvaluationTemplateCreateForm(
            key: key,
            onEditItem: (_) async => null,
            onEditSectionTitle: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.setNameError('Name taken.');
      await tester.pump();
      expect(find.text('Name taken.'), findsOneWidget);
    });
  });

  group('Issue 173: StampBadge colours and DetailRow', () {
    testWidgets('Issue 173: a stamp badge takes its background and '
        'foreground', (tester) async {
      await tester.pumpWidget(
        wrapEvaluation(
          const StampBadge(
            text: 'Ready',
            background: Color(0xFF111111),
            foreground: Color(0xFFEEEEEE),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('READY'));
      expect(text.style!.color, const Color(0xFFEEEEEE));
      final box = tester.widget<Container>(
        find.ancestor(of: find.text('READY'), matching: find.byType(Container)),
      );
      expect((box.decoration! as BoxDecoration).color, const Color(0xFF111111));
    });

    testWidgets('Issue 173: a stamp badge defaults to the website gold', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapEvaluation(const StampBadge(text: 'New')),
      );
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text('NEW'));
      expect(text.style!.color, StampBadge.defaultForeground);
      final box = tester.widget<Container>(
        find.ancestor(of: find.text('NEW'), matching: find.byType(Container)),
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        StampBadge.defaultBackground,
      );
      expect(StampBadge.defaultBackground, const Color(0xFFFFD700));
      expect(StampBadge.defaultForeground, Colors.black87);
    });

    testWidgets('Issue 173: a detail row shows icon, label and value', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapEvaluation(
          const DetailRow(
            icon: LucideIcons.calendar,
            label: 'Review Period',
            value: '1 May 2026 to 31 May 2026',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
      expect(find.text('Review Period'), findsOneWidget);
      expect(find.text('1 May 2026 to 31 May 2026'), findsOneWidget);
    });
  });
}
