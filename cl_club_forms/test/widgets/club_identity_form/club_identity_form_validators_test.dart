import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/club_identity_form/club_identity_form_validators.dart'
    show ClubIdentityFormValidators;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 20: ClubIdentityFormValidators', () {
    test('Issue 20: phone is optional and E.164 when given', () {
      expect(ClubIdentityFormValidators.phone(''), isNull);
      expect(ClubIdentityFormValidators.phone('+919876543210'), isNull);
      expect(ClubIdentityFormValidators.phone('  +14155550123 '), isNull);
      expect(ClubIdentityFormValidators.phone('9876543210'), isNotNull);
      expect(ClubIdentityFormValidators.phone('+91 98765 43210'), isNotNull);
      expect(ClubIdentityFormValidators.phone('+0123456'), isNotNull);
      expect(
        ClubIdentityFormValidators.phone('+1234567890123456'),
        isNotNull,
        reason: 'E.164 allows at most 15 digits',
      );
    });

    test('Issue 20: email is optional and needs the usual shape', () {
      expect(ClubIdentityFormValidators.email(''), isNull);
      expect(ClubIdentityFormValidators.email('desk@club.example'), isNull);
      expect(ClubIdentityFormValidators.email('desk@club'), isNotNull);
      expect(
        ClubIdentityFormValidators.email('desk club@x.example'),
        isNotNull,
      );
      expect(ClubIdentityFormValidators.email('@club.example'), isNotNull);
    });

    test('Issue 20: a URL is optional and must be absolute http(s)', () {
      expect(ClubIdentityFormValidators.url(''), isNull);
      expect(
        ClubIdentityFormValidators.url('https://www.instagram.com/club/'),
        isNull,
      );
      expect(ClubIdentityFormValidators.url('instagram.com/club'), isNotNull);
      expect(ClubIdentityFormValidators.url('/club'), isNotNull);
      expect(ClubIdentityFormValidators.url('ftp://x.example/a'), isNotNull);
      expect(ClubIdentityFormValidators.url('https://'), isNotNull);
    });

    test('Issue 20: a language code is two or three lowercase letters', () {
      expect(ClubIdentityFormValidators.languageCode('mr'), isNull);
      expect(ClubIdentityFormValidators.languageCode('kok'), isNull);
      expect(ClubIdentityFormValidators.languageCode(''), isNotNull);
      expect(ClubIdentityFormValidators.languageCode('MR'), isNotNull);
      expect(ClubIdentityFormValidators.languageCode('marathi'), isNotNull);
      expect(ClubIdentityFormValidators.languageCode('pt-BR'), isNotNull);
    });
  });

  group('Issue 20: FormTranslatedText', () {
    test('Issue 20: trimmed drops empty translations', () {
      const value = FormTranslatedText(' Hello ', {
        'mr': ' Namaskar ',
        'hi': '',
      });
      expect(
        value.trimmed(),
        const FormTranslatedText('Hello', {'mr': 'Namaskar'}),
      );
      expect(const FormTranslatedText('').isEmpty, isTrue);
      expect(const FormTranslatedText('', {'mr': 'x'}).isEmpty, isFalse);
    });
  });
}
