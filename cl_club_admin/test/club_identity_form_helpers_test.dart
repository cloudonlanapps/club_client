import 'package:cl_club_admin/src/models/club_identity_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ClubIdentityForm, FormTranslatedText;

import 'support/admin_test_scope.dart';

typedef _F = ClubIdentityForm;

const _stored = ClubIdentity(
  name: 'Example Club',
  shortName: 'EXC',
  contact: ClubContactDetails(
    phoneNumber: '+10000000000',
    tagline: LocalizedText('Skate with us', {'mr': 'Namaskar'}),
    city: LocalizedText('Example City'),
    extra: {'fax': '+10000000001'},
  ),
  extra: {
    'history': {
      'paragraphs': ['Founded long ago.'],
    },
  },
);

Map<String, dynamic> _values(Map<String, dynamic> overrides) => {
  ..._F.emptyValues,
  ...overrides,
};

void main() {
  group('Issue 20: buildClubIdentityFormInitialValues', () {
    test('Issue 20: maps the identity to the form, translations '
        'included', () {
      final values = buildClubIdentityFormInitialValues(_stored);

      expect(values[_F.nameId], 'Example Club');
      expect(values[_F.shortNameId], 'EXC');
      expect(values[_F.inquiryEmailId], '');
      expect(values[_F.phoneNumberId], '+10000000000');
      expect(
        values[_F.taglineId],
        const FormTranslatedText('Skate with us', {'mr': 'Namaskar'}),
      );
      expect(values[_F.cityId], const FormTranslatedText('Example City'));
      expect(values[_F.stateId], const FormTranslatedText(''));
    });

    test('Issue 20: no identity reads as an empty form', () {
      expect(buildClubIdentityFormInitialValues(null), _F.emptyValues);
      expect(
        buildClubIdentityFormInitialValues(const ClubIdentity()),
        _F.emptyValues,
      );
    });
  });

  group('Issue 20: clubIdentityFromForm', () {
    test('Issue 20: writes the document the website and the server read, '
        'unknown keys kept', () {
      final identity = clubIdentityFromForm(
        values: _values({
          _F.nameId: 'Example Club',
          _F.shortNameId: 'EXC',
          _F.inquiryEmailId: 'desk@club.example',
          _F.phoneNumberId: '+10000000000',
          _F.emailId: 'hello@club.example',
          _F.taglineId: const FormTranslatedText('Skate with us', {
            'mr': 'Namaskar',
          }),
          _F.addressId: const FormTranslatedText('1 Example Street'),
          _F.cityId: const FormTranslatedText('Example City'),
          _F.postalCodeId: '000000',
          _F.instagramUrlId: 'https://www.instagram.com/example/',
        }),
        base: _stored,
      );

      expect(identity.toMap(), {
        'history': {
          'paragraphs': ['Founded long ago.'],
        },
        'name': 'Example Club',
        'shortName': 'EXC',
        'inquiryEmail': 'desk@club.example',
        'contact': {
          'fax': '+10000000001',
          'phoneNumber': '+10000000000',
          'email': 'hello@club.example',
          'tagline': {'default': 'Skate with us', 'mr': 'Namaskar'},
          'address': '1 Example Street',
          'city': 'Example City',
          'postalCode': '000000',
          'instagramUrl': 'https://www.instagram.com/example/',
        },
      });
    });

    test('Issue 20: an emptied field is left out, not written empty', () {
      final identity = clubIdentityFromForm(
        values: _values({_F.nameId: 'Example Club'}),
        base: _stored,
      );

      expect(identity.shortName, isNull);
      expect(identity.contact?.phoneNumber, isNull);
      expect(identity.contact?.tagline, isNull);
      expect(identity.toMap()['contact'], {'fax': '+10000000001'});
    });

    test('Issue 20: no contact block is written when there is none and '
        'nothing is filled in', () {
      final identity = clubIdentityFromForm(
        values: _values({_F.nameId: 'Example Club'}),
        base: const ClubIdentity(),
      );

      expect(identity.toMap(), {'name': 'Example Club'});
    });
  });

  group('Issue 20: ClubIdentityFormSubmit', () {
    test('Issue 20: update saves the whole identity through the '
        'master', () async {
      final stub = StubClubIdentity(_stored);
      final container = ProviderContainer(
        overrides: [clClubIdentityMasterProvider.overrideWith(() => stub)],
      );
      addTearDown(container.dispose);
      await container.read(clClubIdentityMasterProvider.future);

      await ClubIdentityFormSubmit.update(
        values: _values({_F.nameId: 'Renamed Club'}),
        base: _stored,
        notifier: container.read(clClubIdentityMasterProvider.notifier),
      );

      expect(stub.saves.single.name, 'Renamed Club');
      expect(stub.saves.single.extra, _stored.extra);
    });
  });
}
