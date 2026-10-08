// Issue 71, the email and phone rules every form of the package shares.
import 'package:cl_club_forms/src/widgets/common_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

const _emailRequired = 'Email is required';
const _emailInvalid = 'Enter a valid email';
const _phoneRequired = 'Phone number is required';
const _phoneInvalid = 'Enter a valid phone number';

String? _phone(String value, {String code = '91'}) =>
    CommonFormValidators.phone(value, defaultCountryCode: code);

String? _phoneOptional(String value, {String code = '91'}) =>
    CommonFormValidators.phoneOptional(value, defaultCountryCode: code);

void main() {
  group('Issue 71: CommonFormValidators, the email', () {
    test('Issue 71: the messages are the ones the forms show', () {
      expect(CommonFormValidators.emailRequired, _emailRequired);
      expect(CommonFormValidators.emailInvalid, _emailInvalid);
    });

    test('Issue 71: email is required', () {
      expect(CommonFormValidators.email(''), _emailRequired);
      expect(CommonFormValidators.email('  '), _emailRequired);
    });

    test('Issue 71: emailOptional accepts an empty email', () {
      expect(CommonFormValidators.emailOptional(''), isNull);
      expect(CommonFormValidators.emailOptional('  '), isNull);
    });

    const refused = <(String value, String why)>[
      ('@', 'an @ alone'),
      ('a@', 'nothing after the @'),
      ('@b', 'nothing before the @'),
      ('@b.c', 'nothing before the @'),
      ('robin', 'no @'),
      ('robin.example.test', 'no @'),
      ('robin@example', 'no dot in the domain'),
      ('robin@.test', 'nothing before the dot'),
      ('robin@example.', 'nothing after the dot'),
      ('robin@@example.test', 'two @'),
      ('robin@exa@mple.test', 'two @'),
      ('ro bin@example.test', 'a space before the @'),
      ('robin@exam ple.test', 'a space after the @'),
    ];
    for (final (value, why) in refused) {
      test('Issue 71: "$value" is refused as an email: $why', () {
        expect(CommonFormValidators.isEmail(value), isFalse);
        expect(CommonFormValidators.email(value), _emailInvalid);
        expect(CommonFormValidators.emailOptional(value), _emailInvalid);
      });
    }

    for (final value in const [
      'robin@example.test',
      '  robin@example.test ',
      'robin.rao+club@mail.example.test',
      'r@e.t',
      "o'neil_9@example-club.test",
    ]) {
      test('Issue 71: "$value" is accepted as an email', () {
        expect(CommonFormValidators.isEmail(value), isTrue);
        expect(CommonFormValidators.email(value), isNull);
        expect(CommonFormValidators.emailOptional(value), isNull);
      });
    }
  });

  group('Issue 71: CommonFormValidators, the phone', () {
    test('Issue 71: the messages are the ones the forms show', () {
      expect(CommonFormValidators.phoneRequired, _phoneRequired);
      expect(CommonFormValidators.phoneInvalid, _phoneInvalid);
    });

    test('Issue 71: phone is required', () {
      expect(_phone(''), _phoneRequired);
      expect(_phone('   '), _phoneRequired);
    });

    test('Issue 71: phoneOptional accepts an empty phone', () {
      expect(_phoneOptional(''), isNull);
      expect(_phoneOptional('   '), isNull);
    });

    const refused = <(String value, String why)>[
      ('abcdefghij', 'a ten-letter word'),
      ('12345', 'too short'),
      ('+00 123', 'a country code that does not exist'),
      ('987654321', 'one digit short'),
      ('98765432101', 'one digit long'),
      ('98765x3210', 'a letter among the digits'),
      ('9876543210 ext 2', 'words after the number'),
      ('+', 'a + alone'),
      ('-', 'punctuation alone'),
      ('+91', 'a country code alone'),
      ('0000000000', 'no number starts so'),
    ];
    for (final (value, why) in refused) {
      test('Issue 71: "$value" is refused as a phone: $why', () {
        expect(_phone(value), _phoneInvalid);
        expect(_phoneOptional(value), _phoneInvalid);
      });
    }

    const accepted = <(String value, String how)>[
      ('9876543210', 'typed nationally'),
      ('09876543210', 'with a leading 0'),
      ('+919876543210', 'with + and the country code'),
      ('00919876543210', 'with 00 and the country code'),
      ('98765 43210', 'with a space'),
      ('98765-43210', 'with a dash'),
      ('+91 98765-43210', 'with the country code, a space and a dash'),
      ('(98765) 43.210', 'with brackets and a dot'),
      ('  9876543210  ', 'padded'),
    ];
    for (final (value, how) in accepted) {
      test('Issue 71: "$value" is accepted as a phone: $how', () {
        expect(_phone(value), isNull);
        expect(_phoneOptional(value), isNull);
      });
    }

    test('Issue 71: a number of another country passes when typed with its '
        'country code', () {
      for (final value in const [
        '+1 415 555 0123',
        '001 415 555 0123',
        '+44 7400 123456',
        '+33 6 12 34 56 78',
      ]) {
        expect(_phone(value), isNull, reason: value);
      }
    });

    test('Issue 71: a national number is judged in the country the form is '
        'given', () {
      expect(_phone('6 12 34 56 78', code: '33'), isNull);
      expect(_phone('6 12 34 56 78'), _phoneInvalid);
      expect(_phone('07400 123456', code: '44'), isNull);
    });
  });

  group('Issue 71: CommonFormValidators.internationalPhone', () {
    test('Issue 71: it accepts an empty phone', () {
      expect(CommonFormValidators.internationalPhone(''), isNull);
      expect(CommonFormValidators.internationalPhone('  '), isNull);
    });

    test('Issue 71: it accepts a valid number in international format, '
        'padded or not', () {
      for (final value in const [
        '+919876543210',
        ' +919876543210 ',
        '+14155550123',
      ]) {
        expect(
          CommonFormValidators.internationalPhone(value),
          isNull,
          reason: value,
        );
      }
    });

    test('Issue 71: it refuses a number without its country code, or with '
        'spaces or punctuation, and says which format to use', () {
      for (final value in const [
        '9876543210',
        '09876543210',
        '00919876543210',
        '+91 98765 43210',
        '+91-9876543210',
        '+00123',
        'abcdefghij',
      ]) {
        expect(
          CommonFormValidators.internationalPhone(value),
          CommonFormValidators.internationalPhoneFormat,
          reason: value,
        );
      }
    });

    test('Issue 71: it refuses a number in the format that is no number of '
        'its country', () {
      for (final value in const [
        '+91987654321',
        '+9198765432101',
        '+999123456789',
        '+10000000000',
      ]) {
        expect(
          CommonFormValidators.internationalPhone(value),
          _phoneInvalid,
          reason: value,
        );
      }
    });
  });
}
