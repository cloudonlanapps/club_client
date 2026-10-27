// Issue 321: the checks of the application forms. A text needs English
// when written here; a reference names a fact or clause that exists, of the
// right kind, with every gap bound to a fact of the gap's type. A fact has
// an identifier-like name no other fact has and a whole value for its type.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/application/application_form_validators.dart';
import 'package:cl_club_forms/src/widgets/application/application_text_sources.dart';
import 'package:flutter_test/flutter_test.dart';

final ApplicationTextSources _sources = ApplicationTextSources(
  facts: const {
    'venue': ApplicationFactType.name,
    'camp': ApplicationFactType.dateRange,
  },
  clauses: const [
    ApplicationClauseOption(
      id: 'rule.camp',
      kind: ApplicationClauseKind.rule,
      heading: {'en': 'Camp'},
      text: {'en': 'A camp from {dates} at {venue}.'},
      gaps: {
        'dates': ApplicationFactType.dateRange,
        'venue': ApplicationFactType.name,
      },
    ),
    ApplicationClauseOption(
      id: 'declaration.camp',
      kind: ApplicationClauseKind.declaration,
      text: {'en': 'I declare.'},
    ),
  ],
);

String? _text(Object? json, {bool required = false}) =>
    ApplicationFormValidators.text(
      json,
      _sources,
      required: required,
      kind: ApplicationClauseKind.rule,
    );

Map<String, Object?> _fact(String name, String type, Map<String, Object?> v) =>
    {'name': name, 'type': type, ...v};

void main() {
  group('Issue 321: ApplicationFormValidators.text', () {
    test('Issue 321: custom text needs English; an empty optional one is '
        'fine', () {
      expect(_text({'en': 'Bring a helmet.'}), isNull);
      expect(_text({'mr': 'हेल्मेट'}), 'Needs text in English');
      expect(_text(null, required: true), 'Needs text in English');
      expect(_text(null), isNull);
    });

    test('Issue 321: a fact reference names a fact there is', () {
      expect(_text({'fact': 'venue'}), isNull);
      expect(_text({'fact': ''}), 'Choose a fact');
      expect(_text({'fact': 'city'}), 'There is no fact "city"');
    });

    test('Issue 321: a clause is one of the library, of the kind wanted, '
        'every gap bound to a fact of its type', () {
      expect(
        _text({
          'clause': 'rule.camp',
          'args': {'dates': 'camp', 'venue': 'venue'},
        }),
        isNull,
      );
      expect(_text({'clause': ''}), 'Choose a clause');
      expect(
        _text({'clause': 'rule.gone'}),
        'The library has no clause "rule.gone"',
      );
      expect(
        _text({'clause': 'declaration.camp'}),
        '"declaration.camp" cannot be used here',
      );
      expect(
        _text({
          'clause': 'rule.camp',
          'args': {'dates': 'camp'},
        }),
        'Choose a fact for {venue}',
      );
      expect(
        _text({
          'clause': 'rule.camp',
          'args': {'dates': 'venue', 'venue': 'venue'},
        }),
        'The fact "venue" is not a date range, which {dates} needs',
      );
      expect(
        _text({
          'clause': 'rule.camp',
          'args': {'dates': 'trial', 'venue': 'venue'},
        }),
        'There is no fact "trial"',
      );
    });

    test('Issue 321: a joined line checks each part', () {
      expect(
        _text([
          {'fact': 'venue'},
          {'fact': ''},
        ]),
        'Choose a fact',
      );
    });
  });

  group('Issue 321: ApplicationFormValidators.items', () {
    test('Issue 321: the first item in trouble is named by its place', () {
      expect(
        ApplicationFormValidators.items(
          [
            {'en': 'One'},
            {'mr': 'दोन'},
          ],
          'Selection',
          _text,
        ),
        'Selection 2: Needs text in English',
      );
      expect(ApplicationFormValidators.items(null, 'Selection', _text), isNull);
    });
  });

  group('Issue 321: ApplicationFormValidators.facts', () {
    test('Issue 321: each type takes a whole value', () {
      expect(
        ApplicationFormValidators.facts([
          _fact('venue', 'name', {'value': 'City Rink'}),
          _fact('venue_local', 'name', {
            'value': {'en': 'City Rink', 'mr': 'शहर रिंक'},
          }),
          _fact('day', 'date', {'value': '2026-11-19'}),
          _fact('camp', 'date_range', {
            'from': '2026-11-01',
            'to': '2026-11-01',
          }),
          _fact('report', 'time', {'value': '06:00'}),
          _fact('fee', 'amount', {'value': 1500}),
          _fact('kinds', 'choices', {
            'value': ['on_ice'],
          }),
        ]),
        isNull,
      );
    });

    final refused = <(String, List<Object?>, String)>[
      (
        'no name',
        [
          _fact('', 'name', {'value': 'x'}),
        ],
        'Fact 1: Each fact needs a name',
      ),
      (
        'a name not like an identifier',
        [
          _fact('Camp dates', 'name', {'value': 'x'}),
        ],
        'Fact 1: "Camp dates" is not a fact name: use lower-case letters, '
            'digits and _, starting with a letter',
      ),
      (
        'two facts of one name',
        [
          _fact('venue', 'name', {'value': 'x'}),
          _fact('venue', 'name', {'value': 'y'}),
        ],
        'Fact 2: Two facts are named "venue"',
      ),
      (
        'a name with no English',
        [
          _fact('venue', 'name', {
            'value': {'mr': 'रिंक'},
          }),
        ],
        'Fact 1: Needs text in English',
      ),
      (
        'a date not picked',
        [
          _fact('day', 'date', {'value': ''}),
        ],
        'Fact 1: Pick a date',
      ),
      (
        'a range without its last day',
        [
          _fact('camp', 'date_range', {'from': '2026-11-01'}),
        ],
        'Fact 1: Pick the first and the last day',
      ),
      (
        'a range ending before it starts',
        [
          _fact('camp', 'date_range', {
            'from': '2026-11-02',
            'to': '2026-11-01',
          }),
        ],
        'Fact 1: The last day is before the first',
      ),
      (
        'a time not given',
        [
          _fact('report', 'time', {'value': ''}),
        ],
        'Fact 1: Give a time',
      ),
      (
        'no amount',
        [
          _fact('fee', 'amount', <String, Object?>{}),
        ],
        'Fact 1: Give a whole amount',
      ),
      (
        'no choice ticked',
        [
          _fact('kinds', 'choices', {'value': <String>[]}),
        ],
        'Fact 1: Tick at least one choice',
      ),
    ];
    for (final (rule, rows, message) in refused) {
      test('Issue 321: refuses $rule', () {
        expect(ApplicationFormValidators.facts(rows), message);
      });
    }
  });

  group('Issue 321: the other items', () {
    test('Issue 321: an age category needs an English name and its dates '
        'in order', () {
      expect(
        ApplicationFormValidators.ageCategory({
          'label': {'en': 'Under 12'},
          'born_on_or_after': '2014-01-01',
        }),
        isNull,
      );
      expect(
        ApplicationFormValidators.ageCategory({
          'label': {'mr': 'बारा'},
        }),
        'Needs a name in English',
      );
      expect(
        ApplicationFormValidators.ageCategory({
          'label': {'en': 'Odd'},
          'born_on_or_after': '2014-01-01',
          'born_on_or_before': '2013-12-31',
        }),
        'The last birth date is before the first',
      );
    });

    test('Issue 337: a ticked age limit needs a birth date; unticked, '
        'none', () {
      expect(
        ApplicationFormValidators.ageCategory({
          'label': {'en': 'Open'},
          'age_limit': true,
        }),
        'Pick a birth date, or untick Age limit applicable',
      );
      for (final dates in [
        {'born_on_or_after': '2014-01-01'},
        {'born_on_or_before': '2014-12-31'},
        {'born_on_or_after': '2014-01-01', 'born_on_or_before': '2014-01-01'},
      ]) {
        expect(
          ApplicationFormValidators.ageCategory({
            'label': {'en': 'U12'},
            'age_limit': true,
            ...dates,
          }),
          isNull,
          reason: '$dates',
        );
      }
      expect(
        ApplicationFormValidators.ageCategory({
          'label': {'en': 'Open'},
          'age_limit': false,
        }),
        isNull,
      );
    });

    test('Issue 321: a term is a rule clause, or a heading and a text', () {
      expect(
        ApplicationFormValidators.term({
          'clause': 'rule.camp',
          'args': {'dates': 'camp', 'venue': 'venue'},
        }, _sources),
        isNull,
      );
      expect(
        ApplicationFormValidators.term({
          'heading': {'en': 'Kit'},
          'body': {'en': 'Bring a helmet.'},
        }, _sources),
        isNull,
      );
      expect(
        ApplicationFormValidators.term({
          'heading': {'en': 'Kit'},
        }, _sources),
        'Text: Needs text in English',
      );
      expect(
        ApplicationFormValidators.term({
          'body': {'en': 'Bring a helmet.'},
        }, _sources),
        'Heading: Needs text in English',
      );
    });

    test('Issue 321: a note needs its text; the attribution is optional '
        'but needs English', () {
      expect(
        ApplicationFormValidators.note({
          'text': {'en': 'Play fair.'},
        }, _sources),
        isNull,
      );
      expect(
        ApplicationFormValidators.note(<String, Object?>{}, _sources),
        'Needs text in English',
      );
      expect(
        ApplicationFormValidators.note({
          'text': {'en': 'Play fair.'},
          'attribution': {'mr': 'क्लब'},
        }, _sources),
        'Attribution: Needs text in English',
      );
    });
  });
}
