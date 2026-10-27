import 'package:cl_club_applications/src/models/application_form_json.dart';
import 'package:cl_club_applications/src/models/application_form_submit.dart';
import 'package:cl_club_applications/src/models/application_section.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';

void main() {
  group('Issue 321: the template between the SDK and the forms', () {
    test(
      'Issue 321: the forms read snake_case keys and days as YYYY-MM-DD',
      () {
        final json = ApplicationFormJson.fromContent(
          ApplicationSamples.content,
        );

        expect(
          json.keys,
          containsAll(<String>[
            'form_footer',
            'age_categories',
            'terms_notes',
            'label_overrides',
          ]),
        );
        expect(json.keys, isNot(contains('formFooter')));
        final facts = json['facts'] as Map<String, dynamic>;
        expect(facts['trial'], {'type': 'date', 'value': '2026-11-19'});
        expect(facts['camp'], {
          'type': 'date_range',
          'from': '2026-11-01',
          'to': '2026-11-15',
        });
        expect(facts['start'], {'type': 'time', 'value': '06:00'});
        final category = (json['age_categories'] as List).first as Map;
        expect(category['born_on_or_after'], '2014-01-01');
        expect(category['genders'], ['male']);
        expect(json['form_footer'], {'en': 'Play fair', 'mr': 'खेळ'});
      },
    );

    test('Issue 321: a template survives the round trip whole', () {
      final json = ApplicationFormJson.fromContent(ApplicationSamples.content);
      expect(ApplicationFormJson.toContent(json), ApplicationSamples.content);
    });

    test('Issue 321: days go back as UTC-midnight milliseconds', () {
      final content = ApplicationFormJson.toContent({
        'facts': {
          'trial': {'type': 'date', 'value': '2026-11-19'},
        },
        'age_categories': [
          {
            'label': {'en': 'U-12'},
            'born_on_or_before': '2014-12-31',
          },
        ],
      });
      expect(
        content.facts['trial']!.toMap()['value'],
        DateTime.utc(2026, 11, 19).millisecondsSinceEpoch,
      );
      expect(
        content.ageCategories.single.toMap()['bornOnOrBeforeUtc'],
        DateTime.utc(2014, 12, 31).millisecondsSinceEpoch,
      );
      expect(content.ageCategories.single.genders, isNull);
    });

    test('Issue 342: a note is its text and attribution as plain text, a '
        'bare text a note of that text', () {
      final notes = ApplicationFormJson.notes([
        {'en': 'Follow the rules', 'mr': 'नियम'},
        {
          'text': {'en': 'Be early'},
          'attribution': {'en': 'Coach'},
        },
      ]);
      expect(
        notes.first,
        const ApplicationTermsNote(
          text: ApplicationText({'en': 'Follow the rules', 'mr': 'नियम'}),
        ),
      );
      expect(notes.last.text.texts, {'en': 'Be early'});
      expect(notes.last.attribution!.texts, {'en': 'Coach'});
    });

    test('Issue 321: a time the server holds as H:MM reaches the forms as '
        'HH:MM', () {
      expect(
        ApplicationFormJson.factToForm(const ApplicationFact.time('6:30')),
        {'type': 'time', 'value': '06:30'},
      );
    });

    test('Issue 321: a create sends the title and languages', () {
      final content = ApplicationFormJson.toContent({
        'title': {'en': 'Trial 2026'},
        'languages': ['en', 'mr'],
      });
      expect(content.title, const ApplicationText({'en': 'Trial 2026'}));
      expect(content.languages, ['en', 'mr']);
    });
  });

  group('Issue 321: a section sends its own fields alone', () {
    test('Issue 321: the heading sends its five fields under the server '
        'names', () {
      final values = ApplicationFormJson.fromContent(ApplicationSamples.content)
        ..['subtitle'] = null;
      final patch = ApplicationFormSubmit.patchOf({
        for (final key in ApplicationSection.heading.keys) key: values[key],
      });
      expect(patch.toMap().keys, {
        'languages',
        'organisation',
        'title',
        'subtitle',
        'formFooter',
      });
      expect(
        patch.toMap()['subtitle'],
        isNull,
        reason: 'an emptied text clears',
      );
    });

    test('Issue 321: the notes section sends termsNotes only', () {
      final patch = ApplicationFormSubmit.patchOf({
        'terms_notes': [
          {
            'text': {'en': 'Be early'},
          },
        ],
      });
      expect(patch.toMap().keys, ['termsNotes']);
    });

    test('Issue 321: a schema refusal shows on the field the server names', () {
      const error = ServerException(
        statusCode: 422,
        code: SdkErrorCode.validationError,
        message: 'bad',
        details: {
          'fields': [
            {
              'loc': ['body', 'ageCategories', 0, 'label'],
              'msg': 'Value error, needs English',
            },
          ],
        },
      );
      expect(ApplicationFormSubmit.fieldErrorsFor(error), {
        'age_categories': 'Needs English',
      });
    });
  });
}
