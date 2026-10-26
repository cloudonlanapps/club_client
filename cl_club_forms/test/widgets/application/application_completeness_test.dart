// Issue 321: what a template still lacks before it can be saved. Save is
// refused unless the title, the declaration and the footer line are there
// and every one of them, each term, note and selection has text in every
// print language; a clause has the text the library gives it, and a fact
// prints in every language.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, ApplicationClauseOption> _clauses = {
  'declaration.camp': ApplicationClauseOption(
    id: 'declaration.camp',
    kind: ApplicationClauseKind.declaration,
    text: {'en': 'I declare.', 'mr': 'मी घोषित करतो.'},
  ),
  'rule.fee': ApplicationClauseOption(
    id: 'rule.fee',
    kind: ApplicationClauseKind.rule,
    heading: {'en': 'Fee', 'mr': 'शुल्क'},
    text: {'en': 'A fee of {amount}.', 'mr': '{amount} शुल्क.'},
  ),
  'note.english_only': ApplicationClauseOption(
    id: 'note.english_only',
    kind: ApplicationClauseKind.note,
    text: {'en': 'Only in English.'},
  ),
};

Map<String, Object?> _complete() => {
  'languages': ['en', 'mr'],
  'title': {'en': 'Example Club Camp', 'mr': 'उदाहरण शिबिर'},
  'declaration': {'clause': 'declaration.camp'},
  'form_footer': {'en': 'See you there', 'mr': 'भेटूया'},
  'header': [
    {'en': 'City Rink'},
  ],
  'terms': [
    {
      'clause': 'rule.fee',
      'args': {'amount': 'fee'},
    },
    {
      'heading': {'en': 'Kit', 'mr': 'साहित्य'},
      'body': {'en': 'Bring a helmet.', 'mr': 'हेल्मेट आणा.'},
    },
  ],
  'terms_notes': [
    {
      'text': {'fact': 'motto'},
      'attribution': {'en': 'Example Club'},
    },
  ],
  'selections': [
    {'en': 'I will attend.', 'mr': 'मी उपस्थित राहीन.'},
  ],
};

void main() {
  group('Issue 321: ApplicationCompleteness.missingTexts', () {
    test('Issue 321: a complete template lacks nothing; header items and '
        'attributions may stay English only', () {
      expect(
        ApplicationCompleteness.missingTexts(_complete(), clauses: _clauses),
        isEmpty,
      );
    });

    test('Issue 321: a template with no title, declaration or footer lacks '
        'them', () {
      expect(
        ApplicationCompleteness.missingTexts({
          'languages': ['en'],
        }, clauses: _clauses),
        ['title', 'declaration', 'form_footer'],
      );
    });

    test('Issue 321: each text missing a print language is named by its '
        'place', () {
      final template = _complete()
        ..['title'] = {'en': 'Example Club Camp'}
        ..['terms'] = [
          {
            'heading': {'en': 'Kit'},
            'body': {'en': 'Bring a helmet.', 'mr': 'हेल्मेट आणा.'},
          },
          {
            'heading': {'en': 'Kit', 'mr': 'साहित्य'},
            'body': {'en': 'Bring a stick.'},
          },
        ]
        ..['terms_notes'] = [
          {'clause': 'note.english_only'},
        ]
        ..['selections'] = [
          {'en': 'I will attend.'},
        ];

      expect(
        ApplicationCompleteness.missingTexts(template, clauses: _clauses),
        [
          'title',
          'terms[0].heading',
          'terms[1].body',
          'terms_notes[0].text',
          'selections[0]',
        ],
      );
    });

    test('Issue 321: a clause the library does not have is lacking', () {
      final template = _complete()
        ..['declaration'] = {'clause': 'declaration.unknown'};

      expect(
        ApplicationCompleteness.missingTexts(template, clauses: _clauses),
        ['declaration'],
      );
    });

    test('Issue 321: in English alone only what is absent is lacking', () {
      final template = _complete()
        ..['languages'] = ['en']
        ..['title'] = {'en': 'Example Club Camp'}
        ..remove('form_footer');

      expect(
        ApplicationCompleteness.missingTexts(template, clauses: _clauses),
        ['form_footer'],
      );
    });
  });
}
