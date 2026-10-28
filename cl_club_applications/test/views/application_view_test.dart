import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_section.dart';
import 'package:cl_club_applications/src/models/application_template_file.dart';
import 'package:cl_club_applications/src/widgets/application_state_card.dart';
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
  List<String>? names,
  Future<bool> Function(String fileName, Uint8List bytes)? onSaveFile,
  FakeApplicationLabels? labels,
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
      pdfAction: recordingPdfAction(names: names),
      onSaveFile: onSaveFile ?? (_, _) async => true,
    ),
    master: master,
    labels: labels,
  );
  return master;
}

/// The samples' labels and one more, Address, written in English alone.
FakeApplicationLabels _labelsLackingMarathi() => FakeApplicationLabels(
  ApplicationLabels(
    languages: const ['en', 'mr', 'hi'],
    labels: {
      ...ApplicationSamples.labels.labels,
      'field.address': const {'en': 'Address'},
    },
  ),
);

/// The icon button of the heading card's Preview or blank form ([name]).
ShadIconButton _icon(WidgetTester tester, String name) => tester.widget(
  find.descendant(
    of: find.byKey(ValueKey('application.state.$name')),
    matching: find.byType(ShadIconButton),
  ),
);

/// The moves the heading card shows, by name.
List<String> _moves() => [
  for (final step in ['save', 'publish', 'unpublish', 'revert', 'delete'])
    if (find.byKey(ValueKey('application.step.$step')).evaluate().isNotEmpty)
      step,
];

/// The Text of the read line [label] of section [section] showing its
/// value.
Text _readValue(WidgetTester tester, String section, String label) {
  final row = find.ancestor(
    of: find.text(label),
    matching: find.byType(Row),
  );
  final texts = tester
      .widgetList<Text>(
        find.descendant(
          of: find.descendant(
            of: find.byKey(ValueKey('application.section.$section')),
            matching: row.first,
          ),
          matching: find.byType(Text),
        ),
      )
      .toList();
  return texts.firstWhere((t) => t.data != label);
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
    });

    testWidgets('Issue 403: a note reads as its text, then its attribution '
        'on the next line as written; one with none is its text alone', (
      tester,
    ) async {
      await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          termsNotes: const [
            ApplicationTermsNote(
              text: ApplicationText({'en': 'Follow the rules'}),
            ),
            ApplicationTermsNote(
              text: ApplicationText({'en': 'Keys to Success'}),
              attribution: ApplicationText({'en': '— Example Association'}),
            ),
            ApplicationTermsNote(
              text: ApplicationText({'en': 'Play hard'}),
              attribution: ApplicationText({'en': 'A coach'}),
            ),
          ],
        ),
      );
      final notes = ApplicationSection.notes.name;
      expect(
        _readValue(tester, notes, ApplicationViewStrings.note(1)).data,
        'Follow the rules',
      );
      expect(
        _readValue(tester, notes, ApplicationViewStrings.note(2)).data,
        'Keys to Success\n— Example Association',
      );
      expect(
        _readValue(tester, notes, ApplicationViewStrings.note(3)).data,
        'Play hard\nA coach',
      );
    });

    testWidgets('Issue 398: the heading card opens with the title and state, '
        'Preview on the right and no blank form or layout line', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('State'), findsNothing);
      final title = find.byKey(const ValueKey('application.state.title'));
      expect(tester.widget<Text>(title).data, 'Trial (Draft)');
      final preview = find.byKey(const ValueKey('application.state.preview'));
      expect(preview, findsOneWidget);
      expect(
        find.descendant(of: preview, matching: find.byIcon(LucideIcons.eye)),
        findsOneWidget,
      );
      expect(
        tester.getRect(preview).left,
        greaterThan(tester.getRect(title).right - 1),
      );
      expect(
        find.byKey(const ValueKey('application.state.blankForm')),
        findsNothing,
      );
      expect(find.textContaining('Layout'), findsNothing);
    });

    testWidgets('Issue 398: a draft shows Finalize and Delete only', (
      tester,
    ) async {
      await _pump(tester);
      expect(_moves(), ['save', 'delete']);
      expect(_step(tester, 'save').label, 'Finalize');
      expect(_step(tester, 'save').enabled, isTrue);
      expect(find.text('Save it first'), findsNothing);
      expect(find.text('Already a draft'), findsNothing);
    });

    testWidgets('Issue 398: Delete is a bin icon at the bottom right of the '
        'card, and asks first', (tester) async {
      var deleted = 0;
      final master = FakeApplicationsMaster({
        5: ApplicationSamples.template(),
      });
      await pumpApplications(
        tester,
        ApplicationView(
          currentUser: applicationsUser(admin: true),
          applicationId: 5,
          onBack: () {},
          onDeleted: () => deleted++,
          pdfAction: recordingPdfAction(),
          onSaveFile: (_, _) async => true,
        ),
        master: master,
      );
      final delete = find.byKey(const ValueKey('application.step.delete'));
      expect(
        find.descendant(of: delete, matching: find.byIcon(LucideIcons.trash2)),
        findsOneWidget,
      );
      final finalize = tester.getRect(
        find.byKey(const ValueKey('application.step.save')),
      );
      final bin = tester.getRect(delete);
      expect(bin.left, greaterThan(finalize.right));
      expect(bin.bottom, greaterThanOrEqualTo(finalize.bottom - 1));

      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.deleteTitle), findsOneWidget);
      expect(master.calls, isEmpty, reason: 'nothing is deleted before Yes');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(master.calls, isEmpty);
      expect(deleted, 0);

      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ShadDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(master.calls, ['delete 5']);
      expect(deleted, 1);
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
      expect(find.text('Title: Marathi missing'), findsOneWidget);
      expect(find.text('Footer line: not written'), findsOneWidget);
      expect(_step(tester, 'save').enabled, isFalse);
      expect(find.text('2 texts missing'), findsNothing, reason: 'no reason');
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 398: the Missing list is one heading in the error '
        'colour, its lines smaller', (tester) async {
      await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(formFooter: () => null),
      );
      final error = ShadTheme.of(
        tester.element(find.byType(ApplicationView)),
      ).colorScheme.destructive;
      final heading = tester.widget<Text>(
        find.text(ApplicationViewStrings.missingIntro),
      );
      final line = tester.widget<Text>(find.text('Footer line: not written'));
      expect(ApplicationViewStrings.missingIntro, 'Missing:');
      expect(heading.style!.color, error);
      expect(line.style!.color, error);
      expect(line.style!.fontSize, lessThan(heading.style!.fontSize!));
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
      expect(find.text(ApplicationViewStrings.missingIntro), findsOneWidget);
      expect(find.text('Title: Marathi, Hindi missing'), findsOneWidget);
      expect(find.text('Declaration: not written'), findsOneWidget);
      expect(find.text('Footer line: Hindi missing'), findsOneWidget);
      expect(_step(tester, 'save').enabled, isFalse);
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 398: Finalize moves the draft to saved', (
      tester,
    ) async {
      final master = await _pump(tester);
      _step(tester, 'save').onPressed!();
      await tester.pumpAndSettle();
      expect(master.calls, ['save 5']);
      expect(find.text('Trial (Saved)'), findsOneWidget);
      expect(find.text('Application finalized.'), findsOneWidget);
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
          'Finalize was refused: these texts are missing or lack a language. '
          'Footer line: Marathi; Note 2: English, Marathi.',
        ),
        findsOneWidget,
      );
      expect(master.calls, ['save 5']);
    });

    testWidgets('Issue 396: a club label lacking a print language is in the '
        'Missing list, by name, and Finalize is greyed out', (tester) async {
      final master = await _pump(tester, labels: _labelsLackingMarathi());
      expect(find.text(ApplicationViewStrings.missingIntro), findsOneWidget);
      expect(find.text('Label: Address — Marathi missing'), findsOneWidget);
      expect(
        find.textContaining('Label: Full name'),
        findsNothing,
        reason: 'the template overrides it',
      );
      expect(_step(tester, 'save').enabled, isFalse);
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 396: a refusal listing a club label names it', (
      tester,
    ) async {
      final master = await _pump(tester)
        ..failWith = const ApplicationIncompleteException(
          message: 'incomplete',
          missing: [
            ApplicationMissingText(
              field: 'labels.field.full_name',
              languages: ['mr'],
            ),
          ],
        );
      _step(tester, 'save').onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Finalize was refused: these texts are missing or lack a language. '
          'Label: Full name — Marathi.',
        ),
        findsOneWidget,
      );
      expect(master.calls, ['save 5']);
    });

    testWidgets('Issue 396: a print language the club no longer offers is '
        'said inline on Finalize', (tester) async {
      final master = await _pump(tester)
        ..failWith = const ApplicationLanguageNotOfferedException(
          message: 'not offered',
          languages: ['mr'],
        );
      _step(tester, 'save').onPressed!();
      await tester.pumpAndSettle();
      expect(
        find.text(
          ApplicationViewStrings.finalizeLanguageNotOffered(['Marathi']),
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

    testWidgets('Issue 396: a section saved with a language the club does '
        'not offer says so inline in the form', (tester) async {
      final master = await _pump(tester)
        ..failWith = const ApplicationLanguageNotOfferedException(
          message: 'not offered',
          languages: ['mr'],
        );
      final card = find.byKey(const ValueKey('application.section.heading'));
      await tester.tap(
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: card, matching: _input('Trial')),
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
      expect(master.calls, hasLength(1));
      expect(
        find.descendant(
          of: card,
          matching: find.text(
            ApplicationViewStrings.languageNotOffered(['Marathi']),
          ),
        ),
        findsOneWidget,
      );
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
    testWidgets('Issue 398: a saved one is read-only and shows Publish, '
        'Revert to draft and Delete only', (tester) async {
      await _pump(tester, status: ApplicationStatus.saved);
      expect(find.text('Trial (Saved)'), findsOneWidget);
      expect(find.textContaining(_layout.name), findsNothing);
      expect(find.byType(SectionEditButton), findsNothing);
      expect(find.text(ApplicationViewStrings.revertToEdit), findsOneWidget);
      expect(_moves(), ['publish', 'revert', 'delete']);
      expect(_step(tester, 'publish').enabled, isTrue);
      expect(_step(tester, 'revert').label, 'Revert to draft');
      expect(_step(tester, 'revert').enabled, isTrue);
      expect(find.text('Already saved'), findsNothing);
    });

    testWidgets('Issue 398: a published one shows Unpublish only', (
      tester,
    ) async {
      final master = await _pump(tester, status: ApplicationStatus.published);
      expect(find.text('Trial (Published)'), findsOneWidget);
      expect(_moves(), ['unpublish']);
      expect(_step(tester, 'unpublish').enabled, isTrue);
      expect(find.text('Unpublish it first'), findsNothing);
      _step(tester, 'unpublish').onPressed!();
      await tester.pumpAndSettle();
      expect(master.calls, ['unpublish 5']);
    });

    testWidgets('Issue 321: Preview downloads the demo member’s form', (
      tester,
    ) async {
      final master = await _pump(tester, status: ApplicationStatus.published);
      await tester.tap(
        find.byKey(const ValueKey('application.state.preview')),
      );
      await tester.pumpAndSettle();
      expect(master.calls, ['preview 5']);
    });

    testWidgets('Issue 404: Preview is named after the application alone, '
        'with no member', (tester) async {
      final names = <String>[];
      await _pump(tester, status: ApplicationStatus.published, names: names);
      await tester.tap(
        find.byKey(const ValueKey('application.state.preview')),
      );
      await tester.pumpAndSettle();
      expect(names, ['Trial.pdf']);
    });
  });
  group('Issue 393: Download blank form', () {
    testWidgets('Issue 398: an icon right of Preview in the title row, with '
        'the PDF action’s icon', (tester) async {
      await _pump(tester, status: ApplicationStatus.saved);
      final preview = tester.getRect(
        find.byKey(const ValueKey('application.state.preview')),
      );
      final blankForm = find.byKey(
        const ValueKey('application.state.blankForm'),
      );
      final blank = tester.getRect(blankForm);
      expect(blank.left, greaterThanOrEqualTo(preview.right));
      expect(blank.center.dy, moreOrLessEquals(preview.center.dy, epsilon: 1));
      expect(
        find.descendant(
          of: blankForm,
          matching: find.byIcon(LucideIcons.download),
        ),
        findsOneWidget,
      );
      expect(find.text(ApplicationViewStrings.blankForm), findsNothing);
    });

    testWidgets('Issue 398: hidden on a draft', (tester) async {
      await _pump(tester);
      expect(
        find.byKey(const ValueKey('application.state.blankForm')),
        findsNothing,
      );
    });

    for (final status in [
      ApplicationStatus.saved,
      ApplicationStatus.published,
    ]) {
      testWidgets('Issue 393: on for a ${status.wireName} one, handing the '
          'PDF on named after the application', (tester) async {
        final names = <String>[];
        final master = await _pump(tester, status: status, names: names);
        expect(_icon(tester, 'blankForm').enabled, isTrue);
        await tester.tap(
          find.byKey(const ValueKey('application.state.blankForm')),
        );
        await tester.pumpAndSettle();
        expect(master.calls, ['blank 5']);
        expect(names, ['Trial - blank form.pdf']);
      });
    }

    testWidgets('Issue 393: a refusal shows under the button', (tester) async {
      final master = await _pump(tester, status: ApplicationStatus.saved);
      master.failWith = const ServerException(
        statusCode: 422,
        code: SdkErrorCode.applicationNotSaved,
        message: 'raw server words',
      );
      final blankForm = find.byKey(
        const ValueKey('application.state.blankForm'),
      );
      await tester.tap(blankForm);
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.notSaved), findsOneWidget);
      expect(find.textContaining('raw server words'), findsNothing);
      final refusal = tester.getRect(
        find.text(ApplicationViewStrings.notSaved),
      );
      final button = tester.getRect(
        find.descendant(of: blankForm, matching: find.byType(ShadIconButton)),
      );
      expect(refusal.top, greaterThan(button.bottom));
    });
  });

  group('Issue 398: the read views of the sections', () {
    testWidgets('Issue 398: a blank optional text shows nothing; blank '
        'required ones show Required in the error colour', (tester) async {
      await _pump(
        tester,
        content: ApplicationSamples.content.copyWith(
          subtitle: () => null,
          formFooter: () => null,
          declaration: () => null,
        ),
      );
      final error = ShadTheme.of(
        tester.element(find.byType(ApplicationView)),
      ).colorScheme.destructive;
      final subtitle = _readValue(
        tester,
        'heading',
        ApplicationViewStrings.subtitle,
      );
      expect(subtitle.data, isEmpty);
      final footer = _readValue(
        tester,
        'heading',
        ApplicationViewStrings.formFooter,
      );
      expect(footer.data, ApplicationViewStrings.required);
      expect(footer.style!.color, error);
      final declaration = find.byKey(
        const ValueKey('application.section.declaration'),
      );
      expect(
        find.descendant(
          of: declaration,
          matching: find.text(ApplicationViewStrings.required),
        ),
        findsOneWidget,
      );
      expect(find.text(ApplicationViewStrings.required), findsNWidgets(2));
    });

    testWidgets('Issue 398: a written required text shows its value, not '
        'Required', (tester) async {
      await _pump(tester);
      expect(find.text(ApplicationViewStrings.required), findsNothing);
      expect(
        _readValue(tester, 'heading', ApplicationViewStrings.formFooter).data,
        'Play fair / खेळ',
      );
    });

    testWidgets('Issue 398: a read line’s label is larger than its value', (
      tester,
    ) async {
      await _pump(tester);
      final label = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('application.section.heading')),
          matching: find.text(ApplicationViewStrings.title),
        ),
      );
      final value = _readValue(tester, 'heading', ApplicationViewStrings.title);
      expect(label.style!.fontSize, greaterThan(value.style!.fontSize!));
    });
  });

  group('Issue 400: Export JSON', () {
    final export = find.byKey(const ValueKey('application.exportJson'));

    testWidgets('Issue 400: not offered on a draft', (tester) async {
      await _pump(tester);
      expect(export, findsNothing);
      expect(find.text(ApplicationViewStrings.exportJson), findsNothing);
    });

    for (final status in [
      ApplicationStatus.saved,
      ApplicationStatus.published,
    ]) {
      testWidgets('Issue 400: at the foot of a ${status.wireName} one, apart '
          'from the moves, it hands the content file named after the '
          'application to the save', (tester) async {
        final saved = <(String, Uint8List)>[];
        await _pump(
          tester,
          status: status,
          onSaveFile: (name, bytes) async {
            saved.add((name, bytes));
            return true;
          },
        );
        expect(export, findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ApplicationStateCard),
            matching: export,
          ),
          findsNothing,
        );
        expect(
          tester.getTopLeft(export).dy,
          greaterThan(
            tester
                .getBottomLeft(
                  find.byKey(const ValueKey('application.section.labels')),
                )
                .dy,
          ),
        );
        await tester.tap(export);
        await tester.pumpAndSettle();
        expect(saved, hasLength(1));
        expect(saved.single.$1, 'Trial.json');
        expect(
          ApplicationTemplateFile.decode(saved.single.$2),
          ApplicationSamples.content,
        );
        expect(find.text(ApplicationViewStrings.exported), findsOneWidget);
      });
    }

    testWidgets('Issue 400: a cancelled save says nothing', (tester) async {
      await _pump(
        tester,
        status: ApplicationStatus.saved,
        onSaveFile: (_, _) async => false,
      );
      await tester.tap(export);
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.exported), findsNothing);
      expect(find.text(ApplicationViewStrings.exportFailed), findsNothing);
    });

    testWidgets('Issue 400: a failed save is a fixed toast', (tester) async {
      await _pump(
        tester,
        status: ApplicationStatus.saved,
        onSaveFile: (_, _) async => throw StateError('raw platform words'),
      );
      await tester.tap(export);
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.exportFailed), findsOneWidget);
      expect(find.textContaining('raw platform words'), findsNothing);
    });
  });
}
