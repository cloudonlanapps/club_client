// Issue 389: the Library card: the club's own texts, added in a dialog,
// edited in place and deleted after asking; gaps are kept as written.
// Issue 399: the card is shown on Club details (passed in by its screen)
// and renders nothing while applications are off. Issue 396: it lists every
// text, the seeded built-in clauses among them, each editable and
// deletable alike.
import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_library_strings.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';

Future<FakeApplicationLibraryMaster> _pump(
  WidgetTester tester, {
  Map<int, ApplicationLibraryText>? texts,
  bool enabled = true,
}) async {
  final library = FakeApplicationLibraryMaster(
    texts ?? {7: ApplicationSamples.libraryText()},
  );
  await pumpApplications(
    tester,
    const SingleChildScrollView(child: ApplicationLibrarySection()),
    master: FakeApplicationsMaster({1: ApplicationSamples.template(id: 1)}),
    library: library,
    enabled: enabled,
  );
  return library;
}

Finder _textCard(int id) => find.byKey(ValueKey('application.library.$id'));

Finder _button(Finder within, String label) => find.descendant(
  of: within,
  matching: find.widgetWithText(ShadButton, label),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The [index]th text input inside [within].
Finder _input(Finder within, int index) =>
    find.descendant(of: within, matching: find.byType(EditableText)).at(index);

void main() {
  group('Issue 389: the Library section', () {
    testWidgets('Issue 399: renders nothing while applications are off', (
      tester,
    ) async {
      final library = await _pump(tester, enabled: false);
      expect(find.byKey(const ValueKey('application.library')), findsNothing);
      expect(find.text(ApplicationLibraryStrings.add), findsNothing);
      expect(library.calls, isEmpty);
    });

    testWidgets('Issue 389: lists each club text, with where it is used and '
        'its text in each language', (tester) async {
      await _pump(tester);

      final section = find.byKey(const ValueKey('application.library'));
      expect(section, findsOneWidget);
      final card = _textCard(7);
      expect(
        find.descendant(of: card, matching: find.text('Attend the matches')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Selection')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('I will play the matches on {match_dates}.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Text (Marathi)')),
        findsOneWidget,
      );
    });

    testWidgets('Issue 389: an empty library says so', (tester) async {
      await _pump(tester, texts: const {});
      expect(find.text(ApplicationLibraryStrings.empty), findsOneWidget);
    });

    testWidgets('Issue 389: Add text adds a text with its gaps as written, '
        'and closes', (tester) async {
      final library = await _pump(tester, texts: const {});
      await _tap(
        tester,
        find.widgetWithText(ShadButton, ApplicationLibraryStrings.add),
      );
      final dialog = find.byType(ShadDialog);
      expect(dialog, findsOneWidget);

      // Kind: a note.
      final select = find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('ShadSelect<'),
        ),
      );
      await tester.tapAt(tester.getTopLeft(select) + const Offset(24, 16));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Note').last);
      await tester.pumpAndSettle();
      await tester.enterText(_input(dialog, 0), 'Bring kit');
      await tester.enterText(_input(dialog, 1), 'Bring your kit on {trial}.');
      await tester.pump();
      await _tap(tester, _button(dialog, ApplicationViewStrings.save));

      expect(library.calls, ['create note Bring kit']);
      expect(library.lastInput!.text.texts, {
        'en': 'Bring your kit on {trial}.',
      });
      expect(library.lastInput!.heading, isNull);
      expect(find.byType(ShadDialog), findsNothing);
      expect(find.text(ApplicationLibraryStrings.added), findsOneWidget);
      expect(_textCard(70), findsOneWidget);
    });

    testWidgets('Issue 389: a text is edited in place; the patch sends every '
        'field and clears the heading of a kind that is not a term', (
      tester,
    ) async {
      final library = await _pump(tester);
      final card = _textCard(7);
      await _tap(
        tester,
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      await tester.enterText(_input(card, 0), 'Attend every match');
      await tester.pump();
      await _tap(tester, _button(card, ApplicationViewStrings.save));

      expect(library.calls, ['update 7 kind,name,heading,text']);
      expect(library.lastPatch!.toMap(), {
        'kind': 'selection',
        'name': 'Attend every match',
        'heading': null,
        'text': {
          'en': 'I will play the matches on {match_dates}.',
          'mr': 'मी {match_dates} रोजी सामने खेळेन.',
        },
      });
      expect(
        find.descendant(of: card, matching: find.text('Attend every match')),
        findsOneWidget,
      );
    });

    testWidgets('Issue 389: a name the server refuses shows on its field', (
      tester,
    ) async {
      final library = await _pump(tester)
        ..failWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.validationError,
          message: 'bad',
          details: {
            'fields': [
              {
                'loc': ['body', 'name'],
                'msg': 'Value error, name already used',
              },
            ],
          },
        );
      final card = _textCard(7);
      await _tap(
        tester,
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      await tester.enterText(_input(card, 0), 'Other');
      await tester.pump();
      await _tap(tester, _button(card, ApplicationViewStrings.save));
      expect(library.calls, hasLength(1));
      expect(find.text('Name already used'), findsOneWidget);
    });

    testWidgets('Issue 389: Delete asks first, then removes the text', (
      tester,
    ) async {
      final library = await _pump(tester);
      await _tap(
        tester,
        _button(_textCard(7), ApplicationLibraryStrings.delete),
      );
      expect(find.text(ApplicationLibraryStrings.deleteTitle), findsOneWidget);
      await _tap(
        tester,
        find.widgetWithText(ShadButton, ApplicationLibraryStrings.delete).last,
      );
      expect(library.calls, ['delete 7']);
      expect(_textCard(7), findsNothing);
      expect(find.text(ApplicationLibraryStrings.empty), findsOneWidget);
    });
  });

  group("Issue 396: every library text is the club's", () {
    testWidgets('Issue 396: a seeded built-in clause is listed like a text '
        'the club wrote, editable and deletable, and the intro says so', (
      tester,
    ) async {
      final seeded = ApplicationSamples.libraryText(
        id: 3,
        key: 'rule.fee',
        name: 'Fee',
        kind: ApplicationClauseKind.rule,
        heading: const ApplicationText({'en': 'Fee'}),
        text: const ApplicationText({'en': 'A fee of {amount} is payable.'}),
      );
      final library = await _pump(
        tester,
        texts: {3: seeded, 7: ApplicationSamples.libraryText()},
      );

      expect(find.text(ApplicationLibraryStrings.intro), findsOneWidget);
      expect(ApplicationLibraryStrings.intro, isNot(contains('built-in')));
      for (final id in [3, 7]) {
        expect(
          find.descendant(
            of: _textCard(id),
            matching: find.byType(SectionEditButton),
          ),
          findsOneWidget,
        );
        expect(
          _button(_textCard(id), ApplicationLibraryStrings.delete),
          findsOneWidget,
        );
      }

      await _tap(
        tester,
        find.descendant(
          of: _textCard(3),
          matching: find.byType(SectionEditButton),
        ),
      );
      await tester.enterText(_input(_textCard(3), 0), 'Camp fee');
      await tester.pump();
      await _tap(tester, _button(_textCard(3), ApplicationViewStrings.save));
      expect(library.calls, ['update 3 kind,name,heading,text']);
    });

    testWidgets('Issue 396: a text in a language the club does not offer '
        'is refused inline in the form', (tester) async {
      final library = await _pump(tester)
        ..failWith = const ApplicationLanguageNotOfferedException(
          message: 'not offered',
          languages: ['hi'],
        );
      final card = _textCard(7);
      await _tap(
        tester,
        find.descendant(of: card, matching: find.byType(SectionEditButton)),
      );
      await tester.enterText(_input(card, 0), 'Other');
      await tester.pump();
      await _tap(tester, _button(card, ApplicationViewStrings.save));
      expect(library.calls, hasLength(1));
      expect(
        find.descendant(
          of: card,
          matching: find.text(
            ApplicationViewStrings.languageNotOffered(['Hindi']),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 396: Add text refused for a language the club does '
        'not offer says so in the dialog, which stays open', (tester) async {
      final library = await _pump(tester, texts: const {})
        ..failWith = const ApplicationLanguageNotOfferedException(
          message: 'not offered',
          languages: ['hi'],
        );
      await _tap(
        tester,
        find.widgetWithText(ShadButton, ApplicationLibraryStrings.add),
      );
      final dialog = find.byType(ShadDialog);
      final select = find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('ShadSelect<'),
        ),
      );
      await tester.tapAt(tester.getTopLeft(select) + const Offset(24, 16));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Note').last);
      await tester.pumpAndSettle();
      await tester.enterText(_input(dialog, 0), 'Bring kit');
      await tester.enterText(_input(dialog, 1), 'Bring your kit.');
      await tester.pump();
      await _tap(tester, _button(dialog, ApplicationViewStrings.save));

      expect(library.calls, hasLength(1));
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(
            ApplicationViewStrings.languageNotOffered(['Hindi']),
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
