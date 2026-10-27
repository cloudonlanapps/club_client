// Issue 336, Issue 389: tapping a library text pastes it at that one
// place, as written, `{fact}` gaps included, in the print languages: a new
// item of a list section, or the declaration. Nothing is filled and no
// host call is made. Issue 396: every text is the club's, each shown with
// its name, with no built-in or club mark.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';

const String _terms = ApplicationFormFields.termsId;

List<Object?> _items() => [
  {
    'heading': {'en': 'Kit', 'mr': 'साहित्य'},
    'body': {'en': 'Bring a helmet.'},
  },
  {
    'heading': {'en': 'Travel'},
    'body': {'en': 'Arrange your own travel.'},
  },
];

/// A library text using two date-range facts by name, written in three
/// languages; the template prints in two.
const ApplicationClauseOption _clubSelection = ApplicationClauseOption(
  id: '7',
  kind: ApplicationClauseKind.selection,
  name: 'Matches and practice',
  text: {
    'en': 'Matches {match_dates}, practice {practice_dates}.',
    'mr': 'सामने {match_dates}, सराव {practice_dates}.',
    'hi': 'मैच {match_dates}',
  },
);

Future<ApplicationTermsFormState> _pumpTerms(WidgetTester tester) async {
  final key = GlobalKey<ApplicationTermsFormState>();
  await pumpForm(
    tester,
    ApplicationTermsForm(
      key: key,
      initialValues: {_terms: _items()},
      languages: ApplicationSamples.printLanguages,
      clauses: ApplicationSamples.clauses,
    ),
  );
  return key.currentState!;
}

/// Taps the library text reading [text].
Future<void> _tapClause(WidgetTester tester, String text) async {
  final clause = find.text(text);
  await tester.ensureVisible(clause);
  await tester.pumpAndSettle();
  await tester.tap(clause);
  await tester.pumpAndSettle();
}

/// Whether [value] holds plain text maps only: no clause or fact
/// reference anywhere in it.
bool _textOnly(Object? value) => switch (value) {
  final Map<Object?, Object?> map =>
    !map.containsKey('clause') &&
        !map.containsKey('fact') &&
        map.values.every(_textOnly),
  final List<Object?> list => list.every(_textOnly),
  _ => value is String,
};

void main() {
  group('Issue 389: the library pastes its texts as written', () {
    testWidgets('Issue 389: with other edits pending, tapping a rule adds '
        'only that term, gaps as written, and leaves the other edits '
        'alone', (tester) async {
      final state = await _pumpTerms(tester);

      // An edit pending in the first term.
      await typeIn(tester, _terms, 0, 'Kit and gear');

      await _tapClause(tester, 'Camp — A camp runs {dates} at {venue}.');

      final terms = state.validate()![_terms] as List;
      expect(terms, [
        {
          'heading': {'en': 'Kit and gear', 'mr': 'साहित्य'},
          'body': {'en': 'Bring a helmet.'},
        },
        _items()[1],
        {
          'heading': {'en': 'Camp', 'mr': 'शिबिर'},
          'body': {
            'en': 'A camp runs {dates} at {venue}.',
            'mr': '{dates} {venue} येथे शिबिर.',
          },
        },
      ]);
      expect(find.text('A camp runs {dates} at {venue}.'), findsOneWidget);
    });

    testWidgets('Issue 389: a pasted text is then edited like typed text, '
        'its gap renamed', (tester) async {
      final state = await _pumpTerms(tester);
      await _tapClause(tester, 'Fee — A fee of {amount} is payable.');

      // Term 3's English text: after the two terms' four inputs each.
      await typeIn(tester, _terms, 10, 'A fee of ₹{fee} is payable.');

      expect((state.validate()![_terms] as List).last, {
        'heading': {'en': 'Fee', 'mr': 'शुल्क'},
        'body': {'en': 'A fee of ₹{fee} is payable.', 'mr': '{amount} शुल्क.'},
      });
    });

    testWidgets('Issue 396: a library text shows its name, with no club '
        'mark; Issue 389: it is pasted in the print languages alone', (
      tester,
    ) async {
      final key = GlobalKey<ApplicationSelectionsFormState>();
      await pumpForm(
        tester,
        ApplicationSelectionsForm(
          key: key,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          clauses: const [...ApplicationSamples.clauses, _clubSelection],
        ),
      );

      expect(find.text('Matches and practice'), findsOneWidget);
      expect(find.textContaining("Club's text"), findsNothing);
      await _tapClause(
        tester,
        'Matches {match_dates}, practice {practice_dates}.',
      );

      expect(key.currentState!.validate(), {
        ApplicationFormFields.selectionsId: [
          {
            'en': 'Matches {match_dates}, practice {practice_dates}.',
            'mr': 'सामने {match_dates}, सराव {practice_dates}.',
          },
        ],
      });
    });

    testWidgets('Issue 389: a template saved after pasting holds text maps '
        'only, and the declaration takes the text in place of what was '
        'typed', (tester) async {
      final notesKey = GlobalKey<ApplicationNotesFormState>();
      final headerKey = GlobalKey<ApplicationHeaderFormState>();
      final selectionsKey = GlobalKey<ApplicationSelectionsFormState>();
      final declarationKey = GlobalKey<ApplicationDeclarationFormState>();
      final saved = <Type, Map<String, dynamic>?>{};
      for (final form in <Widget>[
        ApplicationHeaderForm(
          key: headerKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
        ),
        ApplicationSelectionsForm(
          key: selectionsKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
        ),
        ApplicationNotesForm(
          key: notesKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
        ),
        ApplicationDeclarationForm(
          key: declarationKey,
          initialValues: const {
            ApplicationFormFields.declarationId: {'en': 'Typed before.'},
          },
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
        ),
      ]) {
        await pumpForm(tester, form);
        final clause = switch (form) {
          ApplicationHeaderForm() => 'Camp: {dates}',
          ApplicationSelectionsForm() => 'I will attend the camp {dates}.',
          ApplicationNotesForm() => 'Follow the rules above.',
          _ => 'I declare the above is true.',
        };
        await _tapClause(tester, clause);
        final values = switch (form) {
          ApplicationHeaderForm() => headerKey.currentState!.validate(),
          ApplicationSelectionsForm() => selectionsKey.currentState!.validate(),
          ApplicationNotesForm() => notesKey.currentState!.validate(),
          _ => declarationKey.currentState!.validate(),
        };
        expect(values, isNotNull, reason: '$clause validates');
        expect(_textOnly(values), isTrue, reason: '$values');
        saved[form.runtimeType] = values;
      }

      expect(saved[ApplicationHeaderForm], {
        ApplicationFormFields.headerId: [
          {'en': 'Camp: {dates}', 'mr': 'शिबिर: {dates}'},
        ],
      });
      expect(saved[ApplicationNotesForm], {
        ApplicationFormFields.termsNotesId: [
          {
            'text': {'en': 'Follow the rules above.', 'mr': 'नियम पाळा.'},
          },
        ],
      });
      expect(saved[ApplicationDeclarationForm], {
        ApplicationFormFields.declarationId: {
          'en': 'I declare the above is true.',
          'mr': 'मी घोषित करतो.',
        },
      });
    });

    testWidgets('Issue 389: with no text of its kind, no library is '
        'offered', (tester) async {
      await pumpForm(
        tester,
        ApplicationTermsForm(
          initialValues: {_terms: _items()},
          languages: ApplicationSamples.printLanguages,
          clauses: [
            for (final c in ApplicationSamples.clauses)
              if (c.kind != ApplicationClauseKind.rule) c,
          ],
        ),
      );
      expect(find.text('From the library'), findsNothing);
    });
  });
}
