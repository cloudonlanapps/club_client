import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_section.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, SectionEditButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';

const _layout = ApplicationLayout(
  name: 'one page, tighter spacing',
  spreadWithGuardian: 1,
  spreadWithoutGuardian: 2,
);

Future<FakeApplicationsMaster> _pump(
  WidgetTester tester, {
  ApplicationStatus status = ApplicationStatus.draft,
  ApplicationContent? content,
}) async {
  final master = FakeApplicationsMaster({
    5: ApplicationSamples.template(
      status: status,
      content: content,
      layout: status == ApplicationStatus.draft ? null : _layout,
    ),
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

Finder _input(String text) => find.byWidgetPredicate(
  (w) => w is EditableText && w.controller.text == text,
);

ActionButton _step(WidgetTester tester, String name) => tester.widget(
  find.byKey(ValueKey('application.step.$name')),
);

void main() {
  group('Issue 321: the editor of a draft', () {
    testWidgets('Issue 321: every section reads as it prints and is editable', (
      tester,
    ) async {
      await _pump(tester);
      for (final section in ApplicationSection.values) {
        expect(find.text(section.title), findsWidgets, reason: section.name);
      }
      expect(find.byType(SectionEditButton), findsNWidgets(9));
      expect(
        find.text('The fee is 500 / ५००'),
        findsOneWidget,
        reason: 'a text reads in each print language',
      );
      expect(find.text('Camp: 1-15 Nov / शिबिर'), findsOneWidget);
      expect(find.text(ApplicationViewStrings.noLayout), findsOneWidget);
    });

    testWidgets('Issue 321: Save is open; Publish and Revert are greyed out '
        'with their reasons', (tester) async {
      await _pump(tester);
      expect(_step(tester, 'save').enabled, isTrue);
      expect(_step(tester, 'publish').enabled, isFalse);
      expect(find.text('Save it first'), findsOneWidget);
      expect(_step(tester, 'revert').enabled, isFalse);
      expect(find.text('Already a draft'), findsOneWidget);
      expect(_step(tester, 'unpublish').enabled, isFalse);
      expect(_step(tester, 'delete').enabled, isTrue);
    });

    testWidgets('Issue 321: the texts still missing are listed and Save is '
        'greyed out before it is tried', (tester) async {
      final master = await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          formFooter: () => null,
          title: () => const ApplicationText({'en': 'Trial'}),
        ),
      );
      expect(
        find.byKey(const ValueKey('application.state.missing')),
        findsOneWidget,
      );
      expect(find.text('• Title: Marathi missing'), findsOneWidget);
      expect(find.text('• Footer line: not written'), findsOneWidget);
      expect(_step(tester, 'save').enabled, isFalse);
      expect(find.text('2 texts missing'), findsOneWidget);
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 387: each missing text names the print languages it '
        'lacks, or says it is not written', (tester) async {
      final master = await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          languages: const ['en', 'mr', 'hi'],
          title: () => const ApplicationText({'en': 'Trial'}),
          declaration: () => null,
          formFooter: () => const ApplicationText({
            'en': 'See you',
            'mr': 'भेटूया',
          }),
        ),
      );
      expect(find.text(ApplicationViewStrings.missingTitle), findsOneWidget);
      expect(find.text(ApplicationViewStrings.missingIntro), findsOneWidget);
      expect(find.text('• Title: Marathi, Hindi missing'), findsOneWidget);
      expect(find.text('• Declaration: not written'), findsOneWidget);
      expect(find.text('• Footer line: Hindi missing'), findsOneWidget);
      expect(_step(tester, 'save').enabled, isFalse);
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 321: Save moves the draft to saved', (tester) async {
      final master = await _pump(tester);
      _step(tester, 'save').onPressed!();
      await tester.pumpAndSettle();
      expect(master.calls, ['save 5']);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.byType(SectionEditButton), findsNothing);
    });

    testWidgets('Issue 321: an incomplete template’s refusal shows inline', (
      tester,
    ) async {
      final master = await _pump(tester)
        ..failWith = const ApplicationIncompleteException(
          message: 'incomplete',
          missing: [
            ApplicationMissingText(field: 'formFooter', languages: ['mr']),
            ApplicationMissingText(
              field: 'termsNotes[1].text',
              languages: ['en', 'mr'],
            ),
          ],
        );
      _step(tester, 'save').onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Save was refused: these texts are missing or lack a language. '
          'Footer line: Marathi; Note 2: English, Marathi.',
        ),
        findsOneWidget,
      );
      expect(master.calls, ['save 5']);
    });

    testWidgets('Issue 321: a form that does not fit says so inline', (
      tester,
    ) async {
      final master = await _pump(tester);
      master.failWith = const ApplicationDoesNotFitException(
        message: 'too long',
        overflowPt: 41.6,
      );
      _step(tester, 'save').onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.text(ApplicationViewStrings.doesNotFit(41.6)),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: a section saves its own fields alone', (
      tester,
    ) async {
      final master = await _pump(tester);
      final card = find.byKey(const ValueKey('application.section.heading'));
      await tester.tap(
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: card,
          matching: _input('Trial'),
        ),
        'Trial 2027',
      );
      await tester.tap(
        find.descendant(
          of: card,
          matching: find.widgetWithText(
            ShadButton,
            ApplicationViewStrings.save,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(master.calls, [
        'update 5 languages,organisation,title,subtitle,formFooter',
      ]);
    });

    testWidgets('Issue 321: a value the server refuses shows on its field', (
      tester,
    ) async {
      final master = await _pump(tester);
      master.failWith = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.validationError,
        message: 'bad',
        details: {
          'fields': [
            {
              'loc': ['body', 'title'],
              'msg': 'Value error, too long for the form',
            },
          ],
        },
      );
      final card = find.byKey(const ValueKey('application.section.heading'));
      await tester.tap(
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: card,
          matching: _input('Trial'),
        ),
        'A much longer trial',
      );
      await tester.tap(
        find.descendant(
          of: card,
          matching: find.widgetWithText(
            ShadButton,
            ApplicationViewStrings.save,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Too long for the form'), findsOneWidget);
    });
  });

  group('Issue 321: the editor of a saved or published template', () {
    testWidgets('Issue 321: a saved one shows its layout, is read-only, and '
        'may be published or reverted', (tester) async {
      await _pump(tester, status: ApplicationStatus.saved);
      expect(
        find.text(ApplicationViewStrings.layout(_layout.name)),
        findsOneWidget,
      );
      expect(find.byType(SectionEditButton), findsNothing);
      expect(find.text(ApplicationViewStrings.revertToEdit), findsOneWidget);
      expect(_step(tester, 'save').enabled, isFalse);
      expect(find.text('Already saved'), findsOneWidget);
      expect(_step(tester, 'publish').enabled, isTrue);
      expect(_step(tester, 'revert').enabled, isTrue);
      expect(_step(tester, 'delete').enabled, isTrue);
    });

    testWidgets('Issue 321: a published one may only be unpublished', (
      tester,
    ) async {
      final master = await _pump(tester, status: ApplicationStatus.published);
      expect(_step(tester, 'unpublish').enabled, isTrue);
      expect(_step(tester, 'delete').enabled, isFalse);
      expect(_step(tester, 'revert').enabled, isFalse);
      expect(find.text('Unpublish it first'), findsNWidgets(2));
      _step(tester, 'unpublish').onPressed!();
      await tester.pumpAndSettle();
      expect(master.calls, ['unpublish 5']);
    });

    testWidgets('Issue 321: Preview downloads the demo member’s form', (
      tester,
    ) async {
      final master = await _pump(tester, status: ApplicationStatus.published);
      await tester.tap(find.text(ApplicationViewStrings.preview));
      await tester.pumpAndSettle();
      expect(master.calls, ['preview 5']);
    });
  });
}
