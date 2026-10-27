// Issue 389: in the editor a library text is pasted as written, gaps
// included, with no fill call; the heading card lists each gap naming no
// fact and keeps Finalize off; the server's refusal shows there too; and the
// Facts heading carries a (?) that explains facts on hover and on tap.
import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_fact_strings.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, SectionEditButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';

Future<FakeApplicationsMaster> _pump(
  WidgetTester tester, {
  ApplicationContent? content,
}) async {
  final master = FakeApplicationsMaster({
    5: ApplicationSamples.template(content: content),
  });
  await pumpApplications(
    tester,
    ApplicationView(
      currentUser: applicationsUser(admin: true),
      applicationId: 5,
      onBack: () {},
      onDeleted: () {},
      pdfAction: recordingPdfAction(),
    ),
    master: master,
  );
  return master;
}

ActionButton _save(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('application.step.save')));

Finder _card(String section) =>
    find.byKey(ValueKey('application.section.$section'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 389: gaps naming no fact', () {
    testWidgets('Issue 389: the State card lists each gap by place and '
        'language, and Save is greyed out', (tester) async {
      final master = await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          selections: [
            const ApplicationText({'en': 'I attend the camp', 'mr': 'शिबिर'}),
            const ApplicationText({
              'en': 'I play on {match_dates} at {venue}',
              'mr': 'मी {match_date} रोजी',
            }),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('application.state.unknownFacts')),
        findsOneWidget,
      );
      expect(
        find.text('Selection 2 (English): no fact named match_dates'),
        findsOneWidget,
      );
      expect(
        find.text('Selection 2 (Marathi): no fact named match_date'),
        findsOneWidget,
      );
      expect(find.textContaining('named venue'), findsNothing);
      expect(_save(tester).enabled, isFalse);
      expect(find.text('2 gaps name no fact'), findsNothing);
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 398: the Unknown facts list is one heading in the '
        'error colour, its lines smaller', (tester) async {
      await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          formFooter: () => const ApplicationText({
            'en': 'See you on {match_day}',
            'mr': '{match_day}',
          }),
        ),
      );
      final error = ShadTheme.of(
        tester.element(find.byType(ApplicationView)),
      ).colorScheme.destructive;
      final heading = tester.widget<Text>(
        find.text(ApplicationFactStrings.unknownIntro),
      );
      final line = tester.widget<Text>(
        find.text('Footer line (English): no fact named match_day'),
      );
      expect(ApplicationFactStrings.unknownIntro, 'Unknown facts:');
      expect(heading.style!.color, error);
      expect(line.style!.color, error);
      expect(line.style!.fontSize, lessThan(heading.style!.fontSize!));
      expect(_save(tester).enabled, isFalse);
    });

    testWidgets('Issue 389: a template whose gaps all name facts may be '
        'saved', (tester) async {
      await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          declaration: () => const ApplicationText({
            'en': 'I attend from {camp} at {venue}',
            'mr': '{camp} {venue}',
          }),
        ),
      );
      expect(
        find.byKey(const ValueKey('application.state.unknownFacts')),
        findsNothing,
      );
      expect(_save(tester).enabled, isTrue);
    });

    testWidgets("Issue 389: the server's unknown-fact refusal shows inline "
        'on the State card', (tester) async {
      final master = await _pump(tester)
        ..failWith = const ApplicationUnknownFactException(
          message: 'raw',
          gaps: [
            ApplicationUnknownGap(
              place: 'header[1][0]',
              language: 'mr',
              gap: 'rink',
            ),
          ],
        );
      _save(tester).onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Save was refused: these gaps name no fact. '
          'Item 2, line 1 (Marathi): no fact named rink.',
        ),
        findsOneWidget,
      );
      expect(master.calls, ['save 5']);
    });
  });

  group('Issue 389: the library pastes as written', () {
    testWidgets('Issue 389: a club text tapped in Selections is added with '
        'its gaps, in the print languages, with no fill call; saving it '
        'sends the selections', (tester) async {
      final master = await _pump(tester);
      final card = _card('selections');
      await _tap(
        tester,
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );

      expect(
        find.descendant(
          of: card,
          matching: find.text("Club's text: Attend the matches"),
        ),
        findsOneWidget,
      );
      await _tap(
        tester,
        find.descendant(
          of: card,
          matching: find.text('I will play the matches on {match_dates}.'),
        ),
      );
      expect(master.calls, isEmpty, reason: 'nothing is filled');

      await _tap(
        tester,
        find.descendant(
          of: card,
          matching: find.widgetWithText(
            ShadButton,
            ApplicationViewStrings.save,
          ),
        ),
      );
      expect(master.calls, ['update 5 selections']);
      expect(master.lastPatch!.toMap()['selections'], [
        {'en': 'I attend the camp', 'mr': 'शिबिर'},
        {'en': 'I bring my own skates', 'mr': 'स्केट्स'},
        {
          'en': 'I will play the matches on {match_dates}.',
          'mr': 'मी {match_dates} रोजी सामने खेळेन.',
        },
      ]);
    });
  });

  group('Issue 389: the Facts help', () {
    Finder help() => find.byKey(const ValueKey('application.facts.help'));

    testWidgets('Issue 389: the (?) sits at the right end of the Facts '
        'heading row', (tester) async {
      await _pump(tester);
      final card = _card('facts');
      final title = tester.getCenter(
        find.descendant(of: card, matching: find.text('Facts')).first,
      );
      final pencil = tester.getCenter(
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      final mark = tester.getCenter(
        find.descendant(of: card, matching: help()),
      );
      expect(mark.dy, closeTo(title.dy, 4));
      expect(mark.dx, greaterThan(pencil.dx));
      expect(help(), findsOneWidget, reason: 'on the Facts card alone');
    });

    testWidgets('Issue 389: a tap opens the help with one example per type, '
        'and another tap closes it', (tester) async {
      await _pump(tester);
      expect(find.text(ApplicationFactStrings.helpTitle), findsNothing);
      await _tap(tester, help());

      expect(find.text(ApplicationFactStrings.helpTitle), findsOneWidget);
      expect(find.text(ApplicationFactStrings.helpIntro), findsOneWidget);
      for (final (type, fact, use) in ApplicationFactStrings.helpExamples) {
        expect(
          find.text(ApplicationFactStrings.helpExample(type, fact, use)),
          findsOneWidget,
        );
      }
      expect(
        find.text(
          'Date range — match_dates = 1–15 Nov 2026: "from {match_dates}" '
          'prints "from 1–15 November 2026"',
        ),
        findsOneWidget,
      );

      await _tap(tester, help());
      expect(find.text(ApplicationFactStrings.helpTitle), findsNothing);
    });

    testWidgets('Issue 389: hovering opens the help and leaving closes '
        'it', (tester) async {
      await _pump(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await tester.ensureVisible(help());
      await tester.pumpAndSettle();
      await mouse.moveTo(tester.getCenter(help()));
      await tester.pumpAndSettle();
      expect(find.text(ApplicationFactStrings.helpTitle), findsOneWidget);

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text(ApplicationFactStrings.helpTitle), findsNothing);
    });
  });
}
