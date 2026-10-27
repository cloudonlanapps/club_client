// Issue 321: the form-local types of an application template. A printed
// text is custom (a text per language), or several of them joined on one
// line; each reads and writes the template's JSON.
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 321: ApplicationTextValue', () {
    test('Issue 321: a map of texts is custom, kept per language, with '
        'notes and empty texts left out', () {
      final value = ApplicationTextValue.fromJson({
        'en': ' Example Club ',
        'mr': '',
        'hi': 'उदाहरण क्लब',
        '_review': 'a note',
      });

      expect(value, isA<ApplicationCustomText>());
      expect(value!.toJson(), {'en': 'Example Club', 'hi': 'उदाहरण क्लब'});
    });

    test('Issue 321: a list is a joined line of its parts', () {
      final value = ApplicationTextValue.fromJson([
        {'en': 'Camp: 16–20 Nov'},
        {'en': 'Phone: 98765 43210'},
      ]);

      expect(value, isA<ApplicationJoinedText>());
      expect((value! as ApplicationJoinedText).parts, hasLength(2));
      expect(value.toJson(), [
        {'en': 'Camp: 16–20 Nov'},
        {'en': 'Phone: 98765 43210'},
      ]);
    });

    test('Issue 321: nothing, or an empty custom text, is no text', () {
      expect(ApplicationTextValue.fromJson(null), isNull);
      expect(ApplicationTextValue.fromJson(const <String, Object?>{}), isNull);
      expect(ApplicationTextValue.fromJson({'en': '  '}), isNull);
    });
  });

  group('Issue 321: the library and catalogue options', () {
    test('Issue 389: a library text pasted into a template keeps its print '
        'languages alone, as written, gaps included', () {
      const clause = ApplicationClauseOption(
        id: 'rule.matches',
        kind: ApplicationClauseKind.rule,
        heading: {'en': 'Matches', 'mr': 'सामने', 'hi': ' '},
        text: {
          'en': ' Matches from {dates} at {venue}. ',
          'mr': '{dates} {venue}',
          'hi': '{dates}',
        },
      );

      final pasted = clause.only(['en', 'mr']);

      expect(pasted.id, 'rule.matches');
      expect(pasted.kind, ApplicationClauseKind.rule);
      expect(pasted.heading, {'en': 'Matches', 'mr': 'सामने'});
      expect(pasted.text, {
        'en': 'Matches from {dates} at {venue}.',
        'mr': '{dates} {venue}',
      });
      expect(clause.only(['en']).heading, {'en': 'Matches'});
    });

    test('Issue 321: every fact type reads and writes its JSON name', () {
      expect(
        [for (final type in ApplicationFactType.values) type.jsonName],
        ['name', 'date', 'date_range', 'time', 'amount', 'choices'],
      );
      for (final type in ApplicationFactType.values) {
        expect(ApplicationFactType.fromJson(type.jsonName), type);
      }
      expect(ApplicationFactType.fromJson('colour'), isNull);
    });

    test('Issue 321: the facts of a template, by name and type', () {
      expect(
        ApplicationFactType.ofFacts({
          'venue': {'type': 'name', 'value': 'City Rink'},
          'camp': {'type': 'date_range', 'from': '2026-11-16'},
          'odd': {'type': 'colour'},
          '_comment': 'a note',
        }),
        {
          'venue': ApplicationFactType.name,
          'camp': ApplicationFactType.dateRange,
        },
      );
      expect(ApplicationFactType.ofFacts(null), isEmpty);
    });
  });
}
