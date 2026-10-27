// Issue 389: the gaps of a template's printed texts that name no fact of
// it, found as the server's Save finds them (club_server#126), so the
// State card lists them and keeps Save off.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

/// A template using a gap in every text the server checks; `known` is the
/// only fact.
Map<String, Object?> _everywhere() => {
  'languages': ['en', 'mr'],
  'facts': {
    'known': {'type': 'name', 'value': 'Rink'},
  },
  'organisation': {'en': '{org} {known}'},
  'title': {'en': 'Camp {title_gap}'},
  'subtitle': {'mr': '{sub}'},
  'header': [
    {'en': 'At {known}'},
    [
      {'en': 'Line {line_a}'},
      {'en': 'Line {line_b}'},
    ],
  ],
  'selections': [
    {'en': 'On {sel}', 'mr': 'वर {sel_mr}'},
  ],
  'declaration': {'en': 'I {decl}'},
  'form_footer': {'en': '{foot}'},
  'terms': [
    {
      'heading': {'en': '{th}'},
      'body': {'en': '{tb}'},
    },
  ],
  'terms_notes': [
    {
      'text': {'en': '{nt}'},
      'attribution': {'en': '{na}'},
    },
  ],
  'label_overrides': {'field.full_name@en': '{not_checked}'},
  'age_categories': [
    {
      'label': {'en': '{not_checked_either}'},
    },
  ],
};

void main() {
  group('Issue 389: ApplicationFactGaps.unknown', () {
    test('Issue 389: lists every unknown gap by place and language, in '
        "print order, the server's places", () {
      expect(ApplicationFactGaps.unknown(_everywhere()), const [
        ApplicationFactGap(place: 'organisation', language: 'en', name: 'org'),
        ApplicationFactGap(place: 'title', language: 'en', name: 'title_gap'),
        ApplicationFactGap(place: 'subtitle', language: 'mr', name: 'sub'),
        ApplicationFactGap(
          place: 'header[1][0]',
          language: 'en',
          name: 'line_a',
        ),
        ApplicationFactGap(
          place: 'header[1][1]',
          language: 'en',
          name: 'line_b',
        ),
        ApplicationFactGap(place: 'selections[0]', language: 'en', name: 'sel'),
        ApplicationFactGap(
          place: 'selections[0]',
          language: 'mr',
          name: 'sel_mr',
        ),
        ApplicationFactGap(place: 'declaration', language: 'en', name: 'decl'),
        ApplicationFactGap(place: 'form_footer', language: 'en', name: 'foot'),
        ApplicationFactGap(
          place: 'terms[0].heading',
          language: 'en',
          name: 'th',
        ),
        ApplicationFactGap(place: 'terms[0].body', language: 'en', name: 'tb'),
        ApplicationFactGap(
          place: 'terms_notes[0].text',
          language: 'en',
          name: 'nt',
        ),
        ApplicationFactGap(
          place: 'terms_notes[0].attribution',
          language: 'en',
          name: 'na',
        ),
      ]);
    });

    test('Issue 389: a gap naming a fact is not listed, and none is listed '
        'once every gap has its fact', () {
      final template = _everywhere();
      final names = {
        for (final gap in ApplicationFactGaps.unknown(template)) gap.name,
      };
      template['facts'] = {
        'known': {'type': 'name', 'value': 'Rink'},
        for (final name in names) name: {'type': 'name', 'value': name},
      };
      expect(ApplicationFactGaps.unknown(template), isEmpty);
    });

    test('Issue 389: only lowercase names are gaps; other brace text is '
        'literal', () {
      expect(
        ApplicationFactGaps.unknown({
          'title': {'en': '{Venue} { x } {1st} {} {_a} {ok_2} {a-b}'},
        }),
        const [
          ApplicationFactGap(place: 'title', language: 'en', name: 'ok_2'),
        ],
      );
    });

    test('Issue 389: a gap repeated in one text is listed once; the print '
        'languages come before any other the text has', () {
      expect(
        ApplicationFactGaps.unknown({
          'languages': ['en', 'mr'],
          'declaration': {
            'hi': '{x}',
            'mr': '{dates} और {dates}',
            'en': 'from {dates} to {dates} at {venue}',
          },
        }),
        const [
          ApplicationFactGap(
            place: 'declaration',
            language: 'en',
            name: 'dates',
          ),
          ApplicationFactGap(
            place: 'declaration',
            language: 'en',
            name: 'venue',
          ),
          ApplicationFactGap(
            place: 'declaration',
            language: 'mr',
            name: 'dates',
          ),
          ApplicationFactGap(place: 'declaration', language: 'hi', name: 'x'),
        ],
      );
    });

    test('Issue 389: a template with no gaps, or no texts, has none', () {
      expect(ApplicationFactGaps.unknown(const {}), isEmpty);
      expect(
        ApplicationFactGaps.unknown({
          'title': {'en': 'Camp'},
          'header': [null, 'odd'],
          'terms': [null],
        }),
        isEmpty,
      );
    });
  });
}
