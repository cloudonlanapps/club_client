import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/utils/contact_urls.dart' show ContactUrls;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

void main() {
  group('Issue 32: contact links', () {
    test('Issue 32: a call link carries the number without its grouping', () {
      expect(ContactUrls.call('+91 98765-43210'), 'tel:+919876543210');
      expect(ContactUrls.call('9876543210'), 'tel:9876543210');
    });

    test('Issue 32: a WhatsApp link carries the international digits and no '
        'message', () {
      expect(
        ContactUrls.whatsApp('+91 98765 43210', defaultCountryCode: '49'),
        'https://wa.me/919876543210',
      );
    });

    test('Issue 32: a WhatsApp link puts the default country code in front '
        'of a bare number', () {
      expect(
        ContactUrls.whatsApp('9876543210', defaultCountryCode: '91'),
        'https://wa.me/919876543210',
      );
      expect(
        ContactUrls.whatsApp('09876543210', defaultCountryCode: '91'),
        'https://wa.me/919876543210',
      );
    });

    test('Issue 32: an email link has a subject only when one is given', () {
      expect(ContactUrls.email('a@example.test'), 'mailto:a@example.test');
      expect(
        ContactUrls.email('a@example.test', subject: ''),
        'mailto:a@example.test',
      );
      expect(
        ContactUrls.email('a@example.test', subject: 'Re: ice time'),
        'mailto:a@example.test?subject=Re%3A%20ice%20time',
      );
    });

    test('Issue 32: only digits with an optional + are a dialable number', () {
      expect(PhoneNumber.isDialable('+91 98765 43210'), isTrue);
      expect(PhoneNumber.isDialable('(020) 555-0100'), isTrue);
      expect(PhoneNumber.isDialable('ask at reception'), isFalse);
      expect(PhoneNumber.isDialable('98765 or 43210'), isFalse);
      expect(PhoneNumber.isDialable(''), isFalse);
      expect(PhoneNumber.isDialable('+'), isFalse);
    });
  });
}
