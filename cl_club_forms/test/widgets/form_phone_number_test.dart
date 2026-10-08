// Issue 71, FormPhoneNumber: a typed number put in international format
// and checked as a number of its country.
import 'package:cl_club_forms/src/widgets/form_phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 71: FormPhoneNumber.toInternational', () {
    const cases = <(String typed, String code, String expected)>[
      ('9876543210', '91', '+919876543210'),
      ('09876543210', '91', '+919876543210'),
      ('98765 43210', '91', '+919876543210'),
      ('98765-43210', '91', '+919876543210'),
      ('(98765) 43.210', '91', '+919876543210'),
      ('+919876543210', '44', '+919876543210'),
      ('+91 98765 43210', '44', '+919876543210'),
      ('00919876543210', '44', '+919876543210'),
      ('0091 98765-43210', '44', '+919876543210'),
      ('7400123456', '44', '+447400123456'),
      ('', '91', ''),
      (' - ', '91', ''),
    ];
    for (final (typed, code, expected) in cases) {
      test('Issue 71: "$typed" with country code $code is "$expected"', () {
        expect(
          FormPhoneNumber.toInternational(typed, defaultCountryCode: code),
          expected,
        );
      });
    }

    test('Issue 71: only one leading 0 is dropped', () {
      expect(
        FormPhoneNumber.toInternational('0123', defaultCountryCode: '91'),
        '+91123',
      );
    });
  });

  group('Issue 71: FormPhoneNumber.isValidInternational', () {
    for (final number in const [
      '+919876543210',
      '+14155550123',
      '+447400123456',
      '+33612345678',
    ]) {
      test('Issue 71: $number is a valid number of its country', () {
        expect(FormPhoneNumber.isValidInternational(number), isTrue);
      });
    }

    const refused = <(String number, String why)>[
      ('', 'empty'),
      ('+', 'no digits'),
      ('919876543210', 'no +'),
      ('+91 9876543210', 'a space'),
      ('+91987654321', 'too short for its country'),
      ('+9198765432101', 'too long for its country'),
      ('+910000000000', 'no number of its country starts so'),
      ('+10000000000', 'no number of its country starts so'),
      ('+9109876543210', 'a trunk 0 after the country code'),
      ('+00123', 'a country code that does not exist'),
      ('+0919876543210', 'a country code that does not exist'),
      ('+91abcdefghij', 'letters'),
      ('+12345678901234567890', 'longer than any number'),
    ];
    for (final (number, why) in refused) {
      test('Issue 71: "$number" is refused: $why', () {
        expect(FormPhoneNumber.isValidInternational(number), isFalse);
      });
    }
  });

  group('Issue 71: FormPhoneNumber.isValid', () {
    test('Issue 71: a national number is judged in the given country', () {
      expect(
        FormPhoneNumber.isValid('9876543210', defaultCountryCode: '91'),
        isTrue,
      );
      expect(
        FormPhoneNumber.isValid('7400 123456', defaultCountryCode: '44'),
        isTrue,
      );
      expect(
        FormPhoneNumber.isValid('6 12 34 56 78', defaultCountryCode: '33'),
        isTrue,
      );
      expect(
        FormPhoneNumber.isValid('6 12 34 56 78', defaultCountryCode: '91'),
        isFalse,
      );
    });

    test('Issue 71: a number with its own country code is judged in that '
        'country', () {
      expect(
        FormPhoneNumber.isValid('+1 415 555 0123', defaultCountryCode: '91'),
        isTrue,
      );
      expect(
        FormPhoneNumber.isValid('0044 7400 123456', defaultCountryCode: '91'),
        isTrue,
      );
    });
  });
}
