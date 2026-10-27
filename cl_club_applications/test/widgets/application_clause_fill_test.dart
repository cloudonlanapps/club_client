// Issue 336: in the editor, tapping a library clause fills it with the
// template's saved facts through the applications master and inserts the
// filled text at that one place; a refusal shows inline under the list.
import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';

const String _rule = 'Fee — A fee of {amount} is payable.';

final Finder _terms = find.byKey(const ValueKey('application.section.terms'));

Future<FakeApplicationsMaster> _pump(WidgetTester tester) async {
  final master = FakeApplicationsMaster({5: ApplicationSamples.template()});
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

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _openTerms(WidgetTester tester) => _tap(
  tester,
  find.descendant(of: _terms, matching: find.byType(SectionEditButton)),
);

Finder _input(String text) => find.descendant(
  of: _terms,
  matching: find.byWidgetPredicate(
    (w) => w is EditableText && w.controller.text == text,
  ),
);

Future<void> _save(WidgetTester tester) => _tap(
  tester,
  find.descendant(
    of: _terms,
    matching: find.widgetWithText(ShadButton, ApplicationViewStrings.save),
  ),
);

void main() {
  group('Issue 336: the editor inserts a filled library clause', () {
    testWidgets('Issue 336: with other edits pending, tapping a clause adds '
        'only that item, filled with the saved facts, and the save holds '
        'text maps only', (tester) async {
      final master = await _pump(tester);
      await _openTerms(tester);

      // An edit pending in the first term.
      await tester.enterText(_input('The fee is 500'), 'The fee is 550');
      await tester.pump();

      await _tap(
        tester,
        find.descendant(of: _terms, matching: find.text(_rule)),
      );

      expect(master.calls, ['fill rule.fee amount']);
      expect(master.lastFillFacts, {
        'amount': const ApplicationFact.amount(500),
      });
      expect(_input('Filled rule.fee.'), findsOneWidget);

      await _save(tester);

      expect(master.calls, ['fill rule.fee amount', 'update 5 terms']);
      expect(master.lastPatch!.toMap()['terms'], [
        {
          'heading': {'en': 'Fee', 'mr': 'शुल्क'},
          'body': {'en': 'The fee is 550', 'mr': '५००'},
        },
        {
          'heading': {'en': 'Kit', 'mr': 'साहित्य'},
          'body': {'en': 'Wear a helmet', 'mr': 'हेल्मेट'},
        },
        {
          'heading': {'en': 'Fee', 'mr': 'शुल्क'},
          'body': {'en': 'Filled rule.fee.', 'mr': 'भरले rule.fee.'},
        },
      ]);
    });

    testWidgets('Issue 336: a refused fill shows inline, not as a toast, and '
        'inserts nothing', (tester) async {
      final master = await _pump(tester)
        ..failWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.applicationInvalidReference,
          message: 'gap amount has no fact',
        );
      await _openTerms(tester);

      await _tap(
        tester,
        find.descendant(of: _terms, matching: find.text(_rule)),
      );

      expect(
        find.descendant(
          of: _terms,
          matching: find.text(ApplicationViewStrings.clauseNotFilled),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(_input('Filled rule.fee.'), findsNothing);

      // Nothing changed, so Save sends nothing.
      await _save(tester);
      expect(master.calls, ['fill rule.fee amount']);
    });
  });
}
