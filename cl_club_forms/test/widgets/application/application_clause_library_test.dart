// Issue 336: tapping a library clause inserts its filled text, at that one
// place: a new item of a list section, or the declaration. The fill is the
// host's call; a refusal shows inline under the clause list.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/models/application/application_clause_fill.dart'
    show ApplicationClauseFacts;
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

/// A host's fill: records each call and answers with [answer].
class _Filler {
  _Filler(this.answer);

  final ApplicationClauseFill Function(String clause) answer;
  final List<List<Object>> calls = [];

  Future<ApplicationClauseFill> call(
    String clause,
    Map<String, String> facts,
  ) async {
    calls.add([clause, facts]);
    return answer(clause);
  }
}

/// Fills a clause in English, Marathi and Hindi, a rule with its heading.
ApplicationClauseFill _filled(String clause) => ApplicationClauseFilled(
  text: {
    'en': 'Filled $clause.',
    'mr': 'भरले $clause.',
    'hi': 'भरा $clause.',
  },
  heading: clause.startsWith('rule.')
      ? const {'en': 'Fee', 'mr': 'शुल्क', 'hi': 'शुल्क'}
      : const {},
);

Future<ApplicationTermsFormState> _pumpTerms(
  WidgetTester tester,
  _Filler filler,
) async {
  final key = GlobalKey<ApplicationTermsFormState>();
  await pumpForm(
    tester,
    ApplicationTermsForm(
      key: key,
      initialValues: {_terms: _items()},
      languages: ApplicationSamples.printLanguages,
      facts: ApplicationSamples.facts,
      clauses: ApplicationSamples.clauses,
      fillClause: filler.call,
    ),
  );
  return key.currentState!;
}

/// Taps the library clause reading [text].
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
  group('Issue 336: the clause library inserts filled text', () {
    testWidgets('Issue 336: with other edits pending, tapping a clause adds '
        'only that item, filled, and leaves the other edits alone', (
      tester,
    ) async {
      final filler = _Filler(_filled);
      final state = await _pumpTerms(tester, filler);

      // An edit pending in the first term.
      await typeIn(tester, _terms, 0, 'Kit and gear');

      await _tapClause(tester, 'Fee — A fee of {amount} is payable.');

      // The gap takes the template's only amount fact.
      expect(filler.calls, [
        [
          'rule.fee',
          {'amount': 'fee'},
        ],
      ]);
      final terms = state.validate()![_terms] as List;
      expect(terms, [
        {
          'heading': {'en': 'Kit and gear', 'mr': 'साहित्य'},
          'body': {'en': 'Bring a helmet.'},
        },
        _items()[1],
        {
          'heading': {'en': 'Fee', 'mr': 'शुल्क'},
          'body': {'en': 'Filled rule.fee.', 'mr': 'भरले rule.fee.'},
        },
      ]);
      expect(find.text('Filled rule.fee.'), findsOneWidget);
    });

    testWidgets('Issue 336: an inserted clause is then edited like typed '
        'text', (tester) async {
      final state = await _pumpTerms(tester, _Filler(_filled));
      await _tapClause(tester, 'Fee — A fee of {amount} is payable.');

      // Term 3's English text: after the two terms' four inputs each.
      await typeIn(tester, _terms, 10, 'A fee of 600 is payable.');

      expect((state.validate()![_terms] as List).last, {
        'heading': {'en': 'Fee', 'mr': 'शुल्क'},
        'body': {'en': 'A fee of 600 is payable.', 'mr': 'भरले rule.fee.'},
      });
    });

    testWidgets('Issue 336: a refused fill shows inline and inserts '
        'nothing', (tester) async {
      final filler = _Filler(
        (_) => const ApplicationClauseRefused('The library refused it.'),
      );
      final state = await _pumpTerms(tester, filler);

      await _tapClause(tester, 'Fee — A fee of {amount} is payable.');

      expect(filler.calls, hasLength(1));
      expect(find.text('The library refused it.'), findsOneWidget);
      expect(state.validate(), {_terms: _items()});
      expect(state.isDirty, isFalse);
    });

    testWidgets('Issue 336: a gap no fact fills is said inline, with no '
        'call', (tester) async {
      final filler = _Filler(_filled);
      final state = await _pumpTerms(tester, filler);

      // {dates} has no fact of its name, and two date ranges to choose
      // from.
      await _tapClause(tester, 'Camp — A camp runs {dates} at {venue}.');

      expect(filler.calls, isEmpty);
      expect(
        find.text(
          'This clause needs a date range fact named "dates". Add it '
          'under Facts and save, then tap the clause again.',
        ),
        findsOneWidget,
      );
      expect(state.validate(), {_terms: _items()});
    });

    testWidgets('Issue 336: a template saved after inserting holds text maps '
        'only', (tester) async {
      final notesKey = GlobalKey<ApplicationNotesFormState>();
      final headerKey = GlobalKey<ApplicationHeaderFormState>();
      final selectionsKey = GlobalKey<ApplicationSelectionsFormState>();
      final declarationKey = GlobalKey<ApplicationDeclarationFormState>();
      final filler = _Filler(_filled);
      for (final form in <Widget>[
        ApplicationHeaderForm(
          key: headerKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          facts: const {'dates': ApplicationFactType.dateRange},
          clauses: ApplicationSamples.clauses,
          fillClause: filler.call,
        ),
        ApplicationSelectionsForm(
          key: selectionsKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          facts: const {'camp': ApplicationFactType.dateRange},
          clauses: ApplicationSamples.clauses,
          fillClause: filler.call,
        ),
        ApplicationNotesForm(
          key: notesKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
          fillClause: filler.call,
        ),
        ApplicationDeclarationForm(
          key: declarationKey,
          initialValues: const {
            ApplicationFormFields.declarationId: {'en': 'Typed before.'},
          },
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
          fillClause: filler.call,
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
      }

      expect(filler.calls, [
        [
          'header.camp',
          {'dates': 'dates'},
        ],
        [
          'selection.attend_camp',
          {'dates': 'camp'},
        ],
        ['note.follow_rules', <String, String>{}],
        ['declaration.camp', <String, String>{}],
      ]);
      // The declaration took the filled text in place of what was typed.
      expect(declarationKey.currentState!.validate(), {
        ApplicationFormFields.declarationId: {
          'en': 'Filled declaration.camp.',
          'mr': 'भरले declaration.camp.',
        },
      });
      expect(find.text('Filled declaration.camp.'), findsOneWidget);
    });

    testWidgets('Issue 336: a note and a selection are added as filled '
        'items', (tester) async {
      final notesKey = GlobalKey<ApplicationNotesFormState>();
      await pumpForm(
        tester,
        ApplicationNotesForm(
          key: notesKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          clauses: ApplicationSamples.clauses,
          fillClause: _Filler(_filled).call,
        ),
      );
      await _tapClause(tester, 'Follow the rules above.');
      expect(notesKey.currentState!.validate(), {
        ApplicationFormFields.termsNotesId: [
          {
            'text': {
              'en': 'Filled note.follow_rules.',
              'mr': 'भरले note.follow_rules.',
            },
          },
        ],
      });

      final selectionsKey = GlobalKey<ApplicationSelectionsFormState>();
      await pumpForm(
        tester,
        ApplicationSelectionsForm(
          key: selectionsKey,
          initialValues: const {},
          languages: ApplicationSamples.printLanguages,
          facts: const {'camp': ApplicationFactType.dateRange},
          clauses: ApplicationSamples.clauses,
          fillClause: _Filler(_filled).call,
        ),
      );
      await _tapClause(tester, 'I will attend the camp {dates}.');
      expect(selectionsKey.currentState!.validate(), {
        ApplicationFormFields.selectionsId: [
          {
            'en': 'Filled selection.attend_camp.',
            'mr': 'भरले selection.attend_camp.',
          },
        ],
      });
    });

    testWidgets('Issue 336: without a fill, no library is offered', (
      tester,
    ) async {
      await pumpForm(
        tester,
        ApplicationTermsForm(
          initialValues: {_terms: _items()},
          languages: ApplicationSamples.printLanguages,
          facts: ApplicationSamples.facts,
          clauses: ApplicationSamples.clauses,
        ),
      );
      expect(find.text('From the library'), findsNothing);
    });
  });

  group('Issue 336: ApplicationClauseFacts.bind', () {
    const fee = ApplicationClauseOption(
      id: 'rule.camp',
      kind: ApplicationClauseKind.rule,
      text: {'en': '{dates} {venue}'},
      gaps: {
        'dates': ApplicationFactType.dateRange,
        'venue': ApplicationFactType.name,
      },
    );

    test('Issue 336: a gap takes the fact of its name and type', () {
      final facts = ApplicationClauseFacts.bind(fee, const {
        'dates': ApplicationFactType.dateRange,
        'trial': ApplicationFactType.dateRange,
        'venue': ApplicationFactType.name,
      });
      expect(facts.bound, {'dates': 'dates', 'venue': 'venue'});
      expect(facts.missing, isEmpty);
    });

    test('Issue 336: otherwise the only fact of its type', () {
      final facts = ApplicationClauseFacts.bind(fee, const {
        'camp': ApplicationFactType.dateRange,
        'rink': ApplicationFactType.name,
        'dates': ApplicationFactType.amount,
      });
      expect(facts.bound, {'dates': 'camp', 'venue': 'rink'});
    });

    test('Issue 336: a gap with no fact, or several to choose from, is '
        'missing', () {
      final facts = ApplicationClauseFacts.bind(fee, const {
        'camp': ApplicationFactType.dateRange,
        'trial': ApplicationFactType.dateRange,
      });
      expect(facts.bound, isEmpty);
      expect(facts.missing, {
        'dates': ApplicationFactType.dateRange,
        'venue': ApplicationFactType.name,
      });
    });
  });
}
