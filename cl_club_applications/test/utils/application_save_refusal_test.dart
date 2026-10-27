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
        'Save was refused: these texts are missing or lack a language. '
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
        'Save was refused: these texts are missing or lack a language. '
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
        'Save was refused: these texts are missing or lack a language. '
        'Footer line: English, Marathi; Term 2 heading: Marathi; '
        'Selection 1: Hindi; Label dob: xx.',
      );
    });

    test('Issue 338: a refusal listing no text is not shown inline', () {
      expect(_refusal(const []), isNull);
    });
  });
}
