import 'package:cl_club_admin/src/models/club_identity_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ClubAddressFormFields,
        ClubContactFormFields,
        ClubDetailsFormFields,
        FormTranslatedText;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/admin_test_scope.dart';

typedef _D = ClubDetailsFormFields;
typedef _C = ClubContactFormFields;
typedef _A = ClubAddressFormFields;

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

/// Every field of every section filled, with keys no form edits.
const _full = ClubIdentity(
  name: 'Example Club',
  shortName: 'EXC',
  inquiryEmail: 'desk@club.example',
  contact: ClubContactDetails(
    phoneNumber: '+10000000000',
    email: 'hello@club.example',
    whatsappNumber: '+10000000002',
    whatsappMessage: LocalizedText('Hi', {'hi': 'Namaste'}),
    emailSubject: LocalizedText('Question'),
    tagline: LocalizedText('Skate with us', {'mr': 'Namaskar'}),
    address: LocalizedText('1 Example Street'),
    addressLine2: LocalizedText('Example Block'),
    city: LocalizedText('Example City', {'mr': 'Udaharan'}),
    state: LocalizedText('Example State'),
    postalCode: '000000',
    instagramUrl: 'https://www.instagram.com/example/',
    extra: {'fax': '+10000000001'},
  ),
  extra: {'history': 'Founded long ago.'},
);

const _emptyValues = <String, dynamic>{
  _D.nameId: '',
  _D.shortNameId: '',
  _D.taglineId: FormTranslatedText(''),
  _D.inquiryEmailId: '',
  _C.phoneNumberId: '',
  _C.whatsappNumberId: '',
  _C.whatsappMessageId: FormTranslatedText(''),
  _C.emailId: '',
  _C.emailSubjectId: FormTranslatedText(''),
  _C.instagramUrlId: '',
  _A.addressId: FormTranslatedText(''),
  _A.addressLine2Id: FormTranslatedText(''),
  _A.cityId: FormTranslatedText(''),
  _A.stateId: FormTranslatedText(''),
  _A.postalCodeId: '',
};

const _emptyClub = <String, dynamic>{
  _D.nameId: '',
  _D.shortNameId: '',
  _D.taglineId: FormTranslatedText(''),
  _D.inquiryEmailId: '',
};

const _emptyContact = <String, dynamic>{
  _C.phoneNumberId: '',
  _C.whatsappNumberId: '',
  _C.whatsappMessageId: FormTranslatedText(''),
  _C.emailId: '',
  _C.emailSubjectId: FormTranslatedText(''),
  _C.instagramUrlId: '',
};

const _emptyAddress = <String, dynamic>{
  _A.addressId: FormTranslatedText(''),
  _A.addressLine2Id: FormTranslatedText(''),
  _A.cityId: FormTranslatedText(''),
  _A.stateId: FormTranslatedText(''),
  _A.postalCodeId: '',
};

/// [map] without [keys], at the top level and inside its contact block.
Map<String, dynamic> _without(
  Map<String, dynamic> map, {
  List<String> keys = const [],
  List<String> contactKeys = const [],
}) {
  final contact = Map<String, dynamic>.of(
    map['contact'] as Map<String, dynamic>,
  )..removeWhere((key, _) => contactKeys.contains(key));
  return Map<String, dynamic>.of(map)
    ..removeWhere((key, _) => keys.contains(key))
    ..['contact'] = contact;
}

Future<(StubClubIdentity, ProviderContainer)> _master(
  ClubIdentity stored,
) async {
  final stub = StubClubIdentity(stored);
  final container = ProviderContainer(
    overrides: [clClubIdentityMasterProvider.overrideWith(() => stub)],
  );
  addTearDown(container.dispose);
  await container.read(clClubIdentityMasterProvider.future);
  return (stub, container);
}

void main() {
  group('Issue 20: buildClubIdentityFormInitialValues', () {
    test('Issue 20: maps the identity to the form, translations '
        'included', () {
      final values = buildClubIdentityFormInitialValues(_stored);

      expect(values[_D.nameId], 'Example Club');
      expect(values[_D.shortNameId], 'EXC');
      expect(values[_D.inquiryEmailId], '');
      expect(values[_C.phoneNumberId], '+10000000000');
      expect(
        values[_D.taglineId],
        const FormTranslatedText('Skate with us', {'mr': 'Namaskar'}),
      );
      expect(values[_A.cityId], const FormTranslatedText('Example City'));
      expect(values[_A.stateId], const FormTranslatedText(''));
    });

    test('Issue 20: no identity reads as an empty form', () {
      expect(buildClubIdentityFormInitialValues(null), _emptyValues);
      expect(
        buildClubIdentityFormInitialValues(const ClubIdentity()),
        _emptyValues,
      );
    });
  });

  group('Issue 58: clubIdentityLanguagesOf', () {
    test('Issue 58: the languages offered are those the stored values '
        'already use, across every translatable field', () {
      expect(clubIdentityLanguagesOf(_full), ['hi', 'mr']);
      expect(clubIdentityLanguagesOf(_stored), ['mr']);
      expect(clubIdentityLanguagesOf(const ClubIdentity()), isEmpty);
      expect(clubIdentityLanguagesOf(null), isEmpty);
    });
  });

  group('Issue 58: a section is stored over the rest of the document', () {
    test('Issue 58: clubDetailsFromForm replaces the Club fields and leaves '
        'the other sections and unknown keys unchanged', () {
      final identity = clubDetailsFromForm(
        values: const {
          _D.nameId: ' Renamed Club ',
          _D.shortNameId: '',
          _D.taglineId: FormTranslatedText('New tagline'),
          _D.inquiryEmailId: 'front@club.example',
        },
        base: _full,
      );

      final expected = _without(_full.toMap(), keys: ['shortName'])
        ..['name'] = 'Renamed Club'
        ..['inquiryEmail'] = 'front@club.example';
      (expected['contact'] as Map<String, dynamic>)['tagline'] = 'New tagline';
      expect(identity.toMap(), expected);
    });

    test('Issue 58: clubContactFromForm replaces the Contact fields and '
        'leaves the other sections and unknown keys unchanged', () {
      final identity = clubContactFromForm(
        values: {
          ..._emptyContact,
          _C.phoneNumberId: '+919876543210',
          _C.emailSubjectId: const FormTranslatedText('Hello', {
            'mr': 'Namaskar',
          }),
        },
        base: _full,
      );

      final expected = _without(
        _full.toMap(),
        contactKeys: [
          'whatsappNumber',
          'whatsappMessage',
          'email',
          'instagramUrl',
        ],
      );
      (expected['contact'] as Map<String, dynamic>)
        ..['phoneNumber'] = '+919876543210'
        ..['emailSubject'] = {'default': 'Hello', 'mr': 'Namaskar'};
      expect(identity.toMap(), expected);
    });

    test('Issue 58: clubAddressFromForm replaces the Address fields and '
        'leaves the other sections and unknown keys unchanged', () {
      final identity = clubAddressFromForm(
        values: {
          ..._emptyAddress,
          _A.cityId: const FormTranslatedText('Other City'),
          _A.postalCodeId: '111111',
        },
        base: _full,
      );

      final expected = _without(
        _full.toMap(),
        contactKeys: ['address', 'addressLine2', 'state'],
      );
      (expected['contact'] as Map<String, dynamic>)
        ..['city'] = 'Other City'
        ..['postalCode'] = '111111';
      expect(identity.toMap(), expected);
    });

    test('Issue 58: an emptied field is left out, not written empty', () {
      final identity = clubContactFromForm(
        values: _emptyContact,
        base: _stored,
      );

      expect(identity.contact?.phoneNumber, isNull);
      expect(identity.toMap()['contact'], {
        'fax': '+10000000001',
        'tagline': {'default': 'Skate with us', 'mr': 'Namaskar'},
        'city': 'Example City',
      });
    });

    test('Issue 58: no contact block is written when there is none and the '
        'section fills nothing in', () {
      expect(
        clubDetailsFromForm(
          values: {..._emptyClub, _D.nameId: 'Example Club'},
          base: const ClubIdentity(),
        ).toMap(),
        {'name': 'Example Club'},
      );
      expect(
        clubAddressFromForm(
          values: _emptyAddress,
          base: const ClubIdentity(name: 'Example Club'),
        ).toMap(),
        {'name': 'Example Club'},
      );
    });
  });

  group('Issue 58: ClubIdentityFormSubmit', () {
    test('Issue 58: updateClub saves the Club section through the master, '
        'the rest as the master read it', () async {
      final (stub, container) = await _master(_full);

      await ClubIdentityFormSubmit.updateClub(
        values: {
          ...buildClubIdentityFormInitialValues(_full),
          _D.nameId: 'Renamed Club',
        },
        base: _full,
        notifier: container.read(clClubIdentityMasterProvider.notifier),
      );

      expect(stub.saves.single, _full.copyWith(name: () => 'Renamed Club'));
    });

    test('Issue 58: updateContact saves the Contact section through the '
        'master, the rest as the master read it', () async {
      final (stub, container) = await _master(_full);

      await ClubIdentityFormSubmit.updateContact(
        values: {
          ...buildClubIdentityFormInitialValues(_full),
          _C.emailId: 'new@club.example',
        },
        base: _full,
        notifier: container.read(clClubIdentityMasterProvider.notifier),
      );

      expect(
        stub.saves.single,
        _full.copyWith(
          contact: () =>
              _full.contact!.copyWith(email: () => 'new@club.example'),
        ),
      );
    });

    test('Issue 58: updateAddress saves the Address section through the '
        'master, the rest as the master read it', () async {
      final (stub, container) = await _master(_full);

      await ClubIdentityFormSubmit.updateAddress(
        values: {
          ...buildClubIdentityFormInitialValues(_full),
          _A.postalCodeId: '111111',
        },
        base: _full,
        notifier: container.read(clClubIdentityMasterProvider.notifier),
      );

      expect(
        stub.saves.single,
        _full.copyWith(
          contact: () => _full.contact!.copyWith(postalCode: () => '111111'),
        ),
      );
    });

    test("Issue 58: a section method ignores the other sections' "
        'values', () async {
      final (stub, container) = await _master(_full);

      await ClubIdentityFormSubmit.updateAddress(
        values: {
          ..._emptyValues,
          ...buildClubIdentityFormInitialValues(_full)
            ..removeWhere((id, _) => !_A.labels.containsKey(id)),
        },
        base: _full,
        notifier: container.read(clClubIdentityMasterProvider.notifier),
      );

      expect(stub.saves.single, _full);
    });
  });
}
