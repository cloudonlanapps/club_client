import 'package:cl_club_applications/src/utils/application_save_refusal.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

String? _refusal(List<ApplicationMissingText> missing) =>
    applicationSaveRefusal(
      ApplicationIncompleteException(message: 'raw', missing: missing),
    );

void main() {
  group('Issue 338: the save refusal names each text’s missing languages', () {
    test('Issue 338: the English title missing names the title and English, '
        'not Marathi', () {
      final message = _refusal(const [
        ApplicationMissingText(field: 'title', languages: ['en']),
      ]);

      expect(
        message,
        'Finalize was refused: these texts are missing or lack a language. '
        'Title: English.',
      );
      expect(message, isNot(contains('Marathi')));
    });

    test('Issue 338: two texts are each named with their own languages', () {
      expect(
        _refusal(const [
          ApplicationMissingText(field: 'title', languages: ['en']),
          ApplicationMissingText(field: 'declaration', languages: ['mr']),
        ]),
        'Finalize was refused: these texts are missing or lack a language. '
        'Title: English; Declaration: Marathi.',
      );
    });

    test('Issue 338: a text missing altogether lacks every language; list '
        'items and labels are named as the editor names them', () {
      expect(
        _refusal(const [
          ApplicationMissingText(field: 'formFooter', languages: ['en', 'mr']),
          ApplicationMissingText(field: 'terms[1].heading', languages: ['mr']),
          ApplicationMissingText(field: 'selections[0]', languages: ['hi']),
          ApplicationMissingText(
            field: 'labelOverrides.dob',
            languages: ['xx'],
          ),
        ]),
        'Finalize was refused: these texts are missing or lack a language. '
        'Footer line: English, Marathi; Term 2 heading: Marathi; '
        'Selection 1: Hindi; Label dob: xx.',
      );
    });

    test('Issue 338: a refusal listing no text is not shown inline', () {
      expect(_refusal(const []), isNull);
    });
  });

  group('Issue 389: the unknown-fact refusal', () {
    test('Issue 389: each gap is named by place, language and name', () {
      expect(
        applicationSaveRefusal(
          const ApplicationUnknownFactException(
            message: 'raw',
            gaps: [
              ApplicationUnknownGap(
                place: 'selections[1]',
                language: 'mr',
                gap: 'match_date',
              ),
              ApplicationUnknownGap(
                place: 'header[0][1]',
                language: 'en',
                gap: 'venue2',
              ),
            ],
          ),
        ),
        'Finalize was refused: these gaps name no fact. '
        'Selection 2 (Marathi): no fact named match_date; '
        'Item 1, line 2 (English): no fact named venue2.',
      );
    });

    test('Issue 389: a refusal naming no gap is a toast', () {
      expect(
        applicationSaveRefusal(
          const ApplicationUnknownFactException(message: 'raw'),
        ),
        isNull,
      );
    });
  });

  group("Issue 396: the club's labels and languages", () {
    const labels = {
      'field.full_name': {'en': 'Full name', 'mr': 'पूर्ण नाव'},
    };

    test('Issue 396: a label lacking a language is named by its English '
        'text', () {
      expect(
        applicationSaveRefusal(
          const ApplicationIncompleteException(
            message: 'raw',
            missing: [
              ApplicationMissingText(field: 'title', languages: ['hi']),
              ApplicationMissingText(
                field: 'labels.field.full_name',
                languages: ['hi'],
              ),
              ApplicationMissingText(
                field: 'labels.field.unknown',
                languages: ['hi', 'mr'],
              ),
            ],
          ),
          labels: labels,
        ),
        'Finalize was refused: these texts are missing or lack a language. '
        'Title: Hindi; Label: Full name — Hindi; '
        'Label: field.unknown — Hindi, Marathi.',
      );
    });

    test('Issue 396: a print language the club does not offer is said '
        'inline, by name', () {
      const error = ApplicationLanguageNotOfferedException(
        message: 'raw',
        languages: ['hi', 'x-klingon'],
      );
      expect(
        applicationSaveRefusal(error),
        'Finalize was refused: the club does not offer Hindi, x-klingon. '
        'Add them in Profile options on Club details, or remove them from '
        'the print languages.',
      );
      expect(
        applicationLanguageRefusal(error),
        'The club does not offer Hindi, x-klingon. Add them in Profile '
        'options on Club details, or leave them out.',
      );
    });

    test('Issue 396: another failure is not a language refusal', () {
      expect(
        applicationLanguageRefusal(
          const ServerException(
            statusCode: 500,
            code: 'INTERNAL_ERROR',
            message: 'down',
          ),
        ),
        isNull,
      );
    });
  });
}
