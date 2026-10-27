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
}
