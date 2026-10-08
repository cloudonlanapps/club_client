import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/club_identity_form/club_identity_form_validators.dart'
    show ClubIdentityFormValidators;
import 'package:cl_club_forms/src/widgets/common_form_validators.dart'
    show CommonFormValidators;
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

    test('Issue 58: a language code already listed is refused', () {
      expect(
        ClubIdentityFormValidators.newLanguageCode(' hi ', const ['mr']),
        isNull,
      );
      expect(
        ClubIdentityFormValidators.newLanguageCode('mr', const ['mr']),
        'mr is already offered',
      );
      expect(
        ClubIdentityFormValidators.newLanguageCode('Marathi', const []),
        contains('two- or three-letter'),
      );
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

  group('Issue 61: ClubIdentityFormValidators.phone', () {
    const message =
        'Use the international format: + and the country code, '
        'digits only (e.g. +919876543210)';

    test('Issue 61: an empty or blank phone passes', () {
      expect(ClubIdentityFormValidators.phone(''), isNull);
      expect(ClubIdentityFormValidators.phone('   '), isNull);
    });

    test('Issue 71: a valid number of its country in international format '
        'passes, padded or not', () {
      for (final phone in [
        '+919876543210',
        ' +14155550123 ',
        '+447400123456',
      ]) {
        expect(ClubIdentityFormValidators.phone(phone), isNull, reason: phone);
      }
    });

    test('Issue 71: a number in the format that is no number of its country '
        'is refused', () {
      for (final phone in [
        '+12',
        '+123456789012345',
        '+91987654321',
        '+9198765432101',
        '+10000000000',
      ]) {
        expect(
          ClubIdentityFormValidators.phone(phone),
          'Enter a valid phone number',
          reason: phone,
        );
      }
    });

    test('Issue 61: one digit, or sixteen, is refused', () {
      expect(ClubIdentityFormValidators.phone('+1'), message);
      expect(ClubIdentityFormValidators.phone('+1234567890123456'), message);
    });

    test('Issue 61: a number without +, with a leading zero, or with '
        'anything but digits is refused', () {
      for (final phone in [
        '919876543210',
        '+0919876543210',
        '+91-9876543210',
        '+91 9876543210',
        '+91(98)76543210',
        '+91x9876543210',
        '++919876543210',
      ]) {
        expect(ClubIdentityFormValidators.phone(phone), message, reason: phone);
      }
    });
  });

  group('Issue 61: ClubIdentityFormValidators.email', () {
    const message = 'Enter a valid email address';

    test('Issue 61: an empty or blank email passes', () {
      expect(ClubIdentityFormValidators.email(''), isNull);
      expect(ClubIdentityFormValidators.email('  '), isNull);
    });

    test('Issue 61: an address is read with the spaces around it trimmed', () {
      expect(ClubIdentityFormValidators.email(' desk@club.example '), isNull);
    });

    test('Issue 61: no @, two @, no dot in the domain, an empty part or a '
        'space inside is refused', () {
      for (final email in [
        'desk.club.example',
        'desk@@club.example',
        'desk@help@club.example',
        'desk@club',
        'desk@',
        'desk@.example',
        'desk@club.',
        'de sk@club.example',
      ]) {
        expect(ClubIdentityFormValidators.email(email), message, reason: email);
      }
    });
  });

  group('Issue 71: ClubIdentityFormValidators.email shares the one email '
      'pattern', () {
    test('Issue 71: it refuses and accepts what CommonFormValidators.isEmail '
        'does, with its own message', () {
      for (final email in ['@', 'a@', '@b', 'a@b', 'a b@c.d', 'a@b.c']) {
        expect(
          ClubIdentityFormValidators.email(email) == null,
          CommonFormValidators.isEmail(email),
          reason: email,
        );
      }
      expect(
        ClubIdentityFormValidators.email('@'),
        'Enter a valid email address',
      );
      expect(
        ClubIdentityFormValidators.emailInvalid,
        'Enter a valid email address',
      );
    });
  });

  group('Issue 61: ClubIdentityFormValidators.url', () {
    const message = 'Enter the full link, starting with https://';

    test('Issue 61: an empty or blank link passes', () {
      expect(ClubIdentityFormValidators.url(''), isNull);
      expect(ClubIdentityFormValidators.url('  '), isNull);
    });

    test('Issue 61: http and https links with a host pass, trimmed', () {
      expect(ClubIdentityFormValidators.url('http://club.example'), isNull);
      expect(
        ClubIdentityFormValidators.url(' https://club.example/a?b=c '),
        isNull,
      );
    });

    test('Issue 61: a link without a scheme, with another scheme or '
        'without a host is refused', () {
      for (final url in [
        'club.example',
        'www.club.example/page',
        '//club.example',
        'mailto:desk@club.example',
        'ftp://club.example',
        'https://',
        'https:///page',
      ]) {
        expect(ClubIdentityFormValidators.url(url), message, reason: url);
      }
    });
  });

  group('Issue 61: ClubIdentityFormValidators.languageCode', () {
    const message =
        'Use a two- or three-letter language code in lowercase, '
        'e.g. mr or hi';

    test('Issue 61: two or three lowercase letters pass, trimmed', () {
      expect(ClubIdentityFormValidators.languageCode('hi'), isNull);
      expect(ClubIdentityFormValidators.languageCode('kok'), isNull);
      expect(ClubIdentityFormValidators.languageCode(' mr '), isNull);
    });

    test('Issue 61: an empty code is refused: this field is not optional', () {
      expect(ClubIdentityFormValidators.languageCode(''), message);
      expect(ClubIdentityFormValidators.languageCode('  '), message);
    });

    test('Issue 61: one letter, four letters, capitals, digits or a region '
        'are refused', () {
      for (final code in [
        'm',
        'mara',
        'Mr',
        'MR',
        'm1',
        '12',
        'pt-BR',
        'm r',
      ]) {
        expect(
          ClubIdentityFormValidators.languageCode(code),
          message,
          reason: code,
        );
      }
    });
  });

  group('Issue 61: ClubIdentityFormValidators.newLanguageCode', () {
    test('Issue 61: a well-formed code that is not listed passes, with '
        'nothing listed too', () {
      expect(
        ClubIdentityFormValidators.newLanguageCode('hi', const ['mr', 'kok']),
        isNull,
      );
      expect(
        ClubIdentityFormValidators.newLanguageCode('hi', const []),
        isNull,
      );
    });

    test('Issue 61: a listed code is refused by name, the spaces around it '
        'trimmed first', () {
      expect(
        ClubIdentityFormValidators.newLanguageCode(' kok ', const [
          'mr',
          'kok',
        ]),
        'kok is already offered',
      );
    });

    test('Issue 61: the shape is checked before the list', () {
      expect(
        ClubIdentityFormValidators.newLanguageCode('MR', const ['MR']),
        contains('two- or three-letter'),
      );
    });
  });
}
