import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

void main() {
  group('Issue 31: PhoneNumber.toInternational', () {
    String india(String typed) =>
        PhoneNumber.toInternational(typed, defaultCountryCode: '91');
    String uk(String typed) =>
        PhoneNumber.toInternational(typed, defaultCountryCode: '44');

    test('Issue 31: a bare number gets the default country code', () {
      expect(india('9876543210'), '+919876543210');
      expect(uk('9876543210'), '+449876543210');
    });

    test('Issue 31: spaces, dashes, dots and brackets are removed', () {
      expect(india('98765 43210'), '+919876543210');
      expect(india('98765-43210'), '+919876543210');
      expect(india('98765.43210'), '+919876543210');
      expect(india('(98765) 43210'), '+919876543210');
      expect(india('  [987] 654-32.10 '), '+919876543210');
      expect(uk('98765 43210'), '+449876543210');
    });

    test('Issue 31: one leading 0 is dropped before the code is added', () {
      expect(india('09876543210'), '+919876543210');
      expect(uk('09876543210'), '+449876543210');
      expect(india('0 98765 43210'), '+919876543210');
    });

    test('Issue 31: a number typed with + keeps its own country code', () {
      expect(india('+449876543210'), '+449876543210');
      expect(india('+44 98765-43210'), '+449876543210');
      expect(uk('+91 (98765) 43210'), '+919876543210');
    });

    test('Issue 31: a leading 00 becomes +', () {
      expect(india('00449876543210'), '+449876543210');
      expect(india('0044 98765 43210'), '+449876543210');
      expect(uk('0091-98765-43210'), '+919876543210');
    });

    test('Issue 31: a number already in international format is unchanged', () {
      const stored = '+919876543210';
      expect(india(stored), stored);
      expect(uk(stored), stored);
      expect(india(india('98765 43210')), stored);
    });

    test('Issue 31: nothing typed stays empty', () {
      expect(india(''), '');
      expect(india('   '), '');
      expect(india(' - ( ) . '), '');
    });
  });

  group('Issue 31: PhoneNumber.toInternationalOrNull', () {
    test('Issue 31: an absent or empty number is null', () {
      expect(
        PhoneNumber.toInternationalOrNull(null, defaultCountryCode: '91'),
        isNull,
      );
      expect(
        PhoneNumber.toInternationalOrNull('  ', defaultCountryCode: '91'),
        isNull,
      );
    });

    test('Issue 31: a typed number is normalised', () {
      expect(
        PhoneNumber.toInternationalOrNull(
          '09876543210',
          defaultCountryCode: '44',
        ),
        '+449876543210',
      );
    });
  });
}
