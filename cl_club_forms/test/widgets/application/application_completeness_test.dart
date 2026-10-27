// Issue 321: what a template still lacks before it can be saved. Save is
// refused unless the title, the declaration and the footer line are there
// and every one of them, each term, note and selection has text in every
// print language.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _complete() => {
  'languages': ['en', 'mr'],
  'title': {'en': 'Example Club Camp', 'mr': 'उदाहरण शिबिर'},
  'declaration': {'en': 'I declare.', 'mr': 'मी घोषित करतो.'},
  'form_footer': {'en': 'See you there', 'mr': 'भेटूया'},
  'header': [
    {'en': 'City Rink'},
  ],
  'terms': [
    {
      'heading': {'en': 'Fee', 'mr': 'शुल्क'},
      'body': {'en': 'A fee of ₹500.', 'mr': '₹500 शुल्क.'},
    },
    {
      'heading': {'en': 'Kit', 'mr': 'साहित्य'},
      'body': {'en': 'Bring a helmet.', 'mr': 'हेल्मेट आणा.'},
    },
  ],
  'terms_notes': [
    {
      'text': {'en': 'Play fair.', 'mr': 'खेळ निष्पक्ष खेळा.'},
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
        ApplicationCompleteness.missingTexts(_complete()),
        isEmpty,
      );
    });

    test('Issue 321: a template with no title, declaration or footer lacks '
        'them', () {
      expect(
        ApplicationCompleteness.missingTexts({
          'languages': ['en'],
        }),
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
          {
            'text': {'en': 'Only in English.'},
          },
        ]
        ..['selections'] = [
          {'en': 'I will attend.'},
        ];

      expect(
        ApplicationCompleteness.missingTexts(template),
        [
          'title',
          'terms[0].heading',
          'terms[1].body',
          'terms_notes[0].text',
          'selections[0]',
        ],
      );
    });

    test('Issue 321: in English alone only what is absent is lacking', () {
      final template = _complete()
        ..['languages'] = ['en']
        ..['title'] = {'en': 'Example Club Camp'}
        ..remove('form_footer');

      expect(
        ApplicationCompleteness.missingTexts(template),
        ['form_footer'],
      );
    });
  });

  group('Issue 387: ApplicationCompleteness.missingLanguages', () {
    test('Issue 387: a complete template lacks no language', () {
      expect(ApplicationCompleteness.missingLanguages(_complete()), isEmpty);
    });

    test('Issue 387: a text written in English only lacks the other print '
        'languages, in their print order', () {
      final template = _complete()
        ..['languages'] = ['en', 'mr', 'hi']
        ..['title'] = {'en': 'Example Club Camp', 'hi': 'शिविर'}
        ..['declaration'] = {'en': 'I declare.', 'mr': 'मी घोषित करतो.'}
        ..['form_footer'] = {'en': 'See you there'}
        ..['terms'] = const <Object?>[]
        ..['terms_notes'] = const <Object?>[]
        ..['selections'] = const <Object?>[];

      expect(ApplicationCompleteness.missingLanguages(template), {
        'title': ['mr'],
        'declaration': ['hi'],
        'form_footer': ['mr', 'hi'],
      });
    });

    test('Issue 387: a required text with nothing written lacks no named '
        'language: it is not written', () {
      final template = _complete()
        ..remove('title')
        ..['form_footer'] = <String, Object?>{'en': '  ', 'mr': ''};

      expect(ApplicationCompleteness.missingLanguages(template), {
        'title': <String>[],
        'form_footer': <String>[],
      });
    });

    test('Issue 387: terms, notes and selections name what they lack', () {
      final template = _complete()
        ..['terms'] = [
          {
            'heading': {'mr': 'शुल्क'},
            'body': {'en': 'A fee of ₹500.', 'mr': '₹500 शुल्क.'},
          },
        ]
        ..['terms_notes'] = [
          {
            'text': {'en': 'Play fair.'},
          },
        ]
        ..['selections'] = [
          {'en': 'I will attend.'},
        ];

      expect(ApplicationCompleteness.missingLanguages(template), {
        'terms[0].heading': ['en'],
        'terms_notes[0].text': ['mr'],
        'selections[0]': ['mr'],
      });
    });

    test('Issue 387: missingTexts lists the same places', () {
      final template = _complete()
        ..remove('declaration')
        ..['title'] = {'en': 'Example Club Camp'};

      expect(
        ApplicationCompleteness.missingTexts(template),
        ApplicationCompleteness.missingLanguages(template).keys.toList(),
      );
    });
  });
}
