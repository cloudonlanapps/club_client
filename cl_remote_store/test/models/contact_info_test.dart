import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// The hosts' bundled `assets/data/contact_info.json` shape.
Map<String, dynamic> _bundled() => {
  'clubName': 'Test Club',
  'phoneNumber': '+911234567890',
  'whatsappNumber': '+91 98765 43210',
  'email': 'club@example.test',
  'whatsappMessage': 'Hello',
  'emailSubject': 'Enquiry',
  'addressLine1': '1 Rink Road',
  'addressLine2': 'Rink District',
  'city': 'Pune',
  'state': 'Maharashtra',
  'postalCode': '411000',
  'instagramUrl': 'https://instagram.example.test/club',
};

void main() {
  group('Issue 53: ContactInfo.fromBundled', () {
    test('Issue 53: reads the bundled shape, plain strings', () {
      final c = ContactInfo.fromBundled(_bundled());

      expect(c.clubName, 'Test Club');
      expect(c.phoneNumber, '+911234567890');
      expect(c.whatsappNumber, '+91 98765 43210');
      expect(c.email, 'club@example.test');
      expect(c.whatsappMessage, const LocalizedText('Hello'));
      expect(c.emailSubject, const LocalizedText('Enquiry'));
      expect(c.addressLine1, const LocalizedText('1 Rink Road'));
      expect(c.city, const LocalizedText('Pune'));
      expect(c.postalCode, '411000');
      expect(c.instagramUrl, 'https://instagram.example.test/club');
      expect(c.tagline, isNull);
    });

    test('Issue 53: a missing required field is a FormatException', () {
      for (final key in ['clubName', 'phoneNumber', 'email']) {
        expect(
          () => ContactInfo.fromBundled(_bundled()..remove(key)),
          throwsFormatException,
          reason: key,
        );
      }
    });

    test('Issue 53: an empty optional field reads as absent', () {
      final c = ContactInfo.fromBundled(
        _bundled()
          ..['whatsappNumber'] = ''
          ..['city'] = '',
      );
      expect(c.whatsappNumber, isNull);
      expect(c.city, isNull);
      expect(c.whatsappOrPhone, '+911234567890');
    });
  });

  group('Issue 53: ContactInfo links take a language code', () {
    const contact = ContactInfo(
      clubName: 'Test Club',
      phoneNumber: '+911234567890',
      email: 'club@example.test',
      whatsappNumber: '+91 98765 43210',
      whatsappMessage: LocalizedText('Hello there', {'mr': 'नमस्कार'}),
      emailSubject: LocalizedText('Enquiry', {'mr': 'चौकशी'}),
      addressLine1: LocalizedText('1 Rink Road', {'mr': '१ रिंक रोड'}),
      city: LocalizedText('Pune', {'mr': 'पुणे'}),
      postalCode: '411000',
    );

    test('Issue 53: WhatsApp link, per language, digits only', () {
      expect(
        contact.whatsappUrl('en'),
        'https://wa.me/919876543210?text=Hello%20there',
      );
      expect(
        contact.whatsappUrl('mr'),
        'https://wa.me/919876543210?text=${Uri.encodeComponent('नमस्कार')}',
      );
    });

    test('Issue 53: WhatsApp falls back to the phone, no message', () {
      const plain = ContactInfo(
        clubName: 'Test Club',
        phoneNumber: '+911234567890',
        email: 'club@example.test',
      );
      expect(plain.whatsappUrl('en'), 'https://wa.me/911234567890');
    });

    test('Issue 53: email link, per language; tel link', () {
      expect(
        contact.emailUrl('en'),
        'mailto:club@example.test?subject=Enquiry',
      );
      expect(
        contact.emailUrl('mr'),
        'mailto:club@example.test?subject=${Uri.encodeComponent('चौकशी')}',
      );
      expect(contact.phoneUrl, 'tel:+911234567890');
    });

    test('Issue 53: the postal address, per language', () {
      expect(contact.hasAddress, isTrue);
      expect(contact.fullAddress('en'), '1 Rink Road\nPune, 411000');
      expect(contact.fullAddress('mr'), '१ रिंक रोड\nपुणे, 411000');
    });
  });

  group('Issue 53: ContactInfo is a data class', () {
    test('Issue 53: toMap / fromMap round-trip, translations kept', () {
      final c = ContactInfo.fromBundled(_bundled()).copyWith(
        tagline: () => const LocalizedText('Skate', {'mr': 'स्केट'}),
      );
      expect(ContactInfo.fromMap(c.toMap()), c);
      expect(ContactInfo.fromJson(c.toJson()), c);
      expect(ContactInfo.fromMap(c.toMap()).hashCode, c.hashCode);
    });

    test('Issue 53: copyWith can clear a nullable field', () {
      final c = ContactInfo.fromBundled(_bundled());
      expect(c.copyWith(city: () => null).city, isNull);
      expect(c.copyWith().city, c.city);
    });
  });

  group(
    'Issue 53: contactInfoFromServer prefers the server field by field',
    () {
      final fallback = ContactInfo.fromBundled(_bundled());

      test('Issue 53: the name and every contact field the server fills', () {
        const identity = ClubIdentity(
          name: 'Server Club',
          contact: ClubContactDetails(
            phoneNumber: '+10000000001',
            email: 'server@example.test',
            whatsappNumber: '+10000000002',
            whatsappMessage: LocalizedText('Hi', {'mr': 'नमस्ते'}),
            emailSubject: LocalizedText('Subject'),
            tagline: LocalizedText('Tagline'),
            address: LocalizedText('2 Server Street'),
            addressLine2: LocalizedText('Line 2'),
            city: LocalizedText('Mumbai'),
            state: LocalizedText('MH'),
            postalCode: '400001',
            instagramUrl: 'https://instagram.example.test/server',
          ),
        );
        final c = contactInfoFromServer(identity, fallback: fallback);

        expect(c.clubName, 'Server Club');
        expect(c.phoneNumber, '+10000000001');
        expect(c.email, 'server@example.test');
        expect(c.whatsappNumber, '+10000000002');
        expect(c.whatsappMessage, const LocalizedText('Hi', {'mr': 'नमस्ते'}));
        expect(c.emailSubject, const LocalizedText('Subject'));
        expect(c.tagline, const LocalizedText('Tagline'));
        expect(c.addressLine1, const LocalizedText('2 Server Street'));
        expect(c.addressLine2, const LocalizedText('Line 2'));
        expect(c.city, const LocalizedText('Mumbai'));
        expect(c.state, const LocalizedText('MH'));
        expect(c.postalCode, '400001');
        expect(c.instagramUrl, 'https://instagram.example.test/server');
      });

      test('Issue 53: a field the server left out, or empty, is bundled', () {
        const identity = ClubIdentity(
          name: '',
          contact: ClubContactDetails(
            phoneNumber: '+10000000001',
            email: '',
            city: LocalizedText(''),
          ),
        );
        final c = contactInfoFromServer(identity, fallback: fallback);

        expect(c.phoneNumber, '+10000000001');
        expect(c.clubName, fallback.clubName);
        expect(c.email, fallback.email);
        expect(c.city, fallback.city);
        expect(c.whatsappNumber, fallback.whatsappNumber);
        expect(c.addressLine1, fallback.addressLine1);
        expect(c.instagramUrl, fallback.instagramUrl);
      });

      test('Issue 53: an unconfigured server is the bundled block', () {
        expect(
          contactInfoFromServer(const ClubIdentity(), fallback: fallback),
          fallback,
        );
      });
    },
  );
}
