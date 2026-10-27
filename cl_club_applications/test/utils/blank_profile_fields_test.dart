import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/utils/blank_profile_fields.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

typedef S = ApplicationViewStrings;

final DateTime _today = DateTime(2026, 10, 27);

/// A member whose every printed field is filled, born [dateOfBirthUtc].
UserPrivate complete({DateTime? dateOfBirthUtc}) => UserPrivate(
  username: 'robin',
  displayName: 'Robin',
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  firstName: 'Robin',
  lastName: 'Hood',
  dateOfBirthUtc: dateOfBirthUtc ?? DateTime.utc(2000, 3, 4),
  gender: Gender.male,
  phone: '+919800000000',
  email: 'robin@example.com',
  address: const Address(city: 'Pune'),
  nationality: 'Indian',
  preferredLanguage: 'Marathi',
  clubDistrict: 'Pune',
  preferredPosition: 'Forward',
  pastExperience: 'Two seasons',
  guardian: const Guardian(name: 'Marian'),
);

List<String> blank(UserPrivate user, {bool extendedProfile = true}) =>
    blankProfileFields(user, extendedProfile: extendedProfile, today: _today);

void main() {
  group('Issue 340: blankProfileFields', () {
    test('Issue 340: a complete profile has nothing blank', () {
      expect(blank(complete()), isEmpty);
      expect(blank(complete(dateOfBirthUtc: DateTime.utc(2015))), isEmpty);
    });

    final cases = <String, UserPrivate Function(UserPrivate)>{
      S.fieldFirstName: (u) => u.copyWith(firstName: () => '  '),
      S.fieldLastName: (u) => u.copyWith(lastName: () => null),
      S.fieldGender: (u) => u.copyWith(gender: () => null),
      S.fieldPhone: (u) => u.copyWith(phone: () => ''),
      S.fieldEmail: (u) => u.copyWith(email: () => null),
      S.fieldAddress: (u) => u.copyWith(address: () => const Address()),
      S.fieldNationality: (u) => u.copyWith(nationality: () => ' '),
      S.fieldPreferredLanguage: (u) =>
          u.copyWith(preferredLanguage: () => null),
      S.fieldClubDistrict: (u) => u.copyWith(clubDistrict: () => ''),
      S.fieldPreferredPosition: (u) =>
          u.copyWith(preferredPosition: () => null),
      S.fieldPastExperience: (u) => u.copyWith(pastExperience: () => null),
    };
    for (final MapEntry(key: label, value: clear) in cases.entries) {
      test('Issue 340: a blank $label is listed', () {
        expect(blank(clear(complete())), [label]);
      });
    }

    test('Issue 340: an address with no part filled is blank', () {
      final user = complete().copyWith(
        address: () => const Address(addrLine1: ' ', city: '', pincode: null),
      );
      expect(blank(user), [S.fieldAddress]);
      expect(blank(complete().copyWith(address: () => null)), [
        S.fieldAddress,
      ]);
    });

    test(
      'Issue 340: a guardian with no name or phone is blank for a minor',
      () {
        final minor = complete(dateOfBirthUtc: DateTime.utc(2015, 1, 1));
        expect(
          blank(
            minor.copyWith(guardian: () => const Guardian(relation: 'Mother')),
          ),
          [S.fieldGuardian],
        );
        expect(blank(minor.copyWith(guardian: () => null)), [S.fieldGuardian]);
        expect(
          blank(
            minor.copyWith(guardian: () => const Guardian(phone: '+91 98')),
          ),
          isEmpty,
        );
      },
    );

    test('Issue 340: the extended fields are listed only while the extended '
        'profile is on', () {
      final user = complete(dateOfBirthUtc: DateTime.utc(2015)).copyWith(
        nationality: () => null,
        preferredLanguage: () => null,
        clubDistrict: () => null,
        preferredPosition: () => null,
        pastExperience: () => null,
        guardian: () => null,
      );
      expect(blank(user, extendedProfile: false), isEmpty);
      expect(blank(user), [
        S.fieldNationality,
        S.fieldPreferredLanguage,
        S.fieldClubDistrict,
        S.fieldPreferredPosition,
        S.fieldPastExperience,
        S.fieldGuardian,
      ]);
    });

    test('Issue 340: the guardian is listed at 17 and not at 18', () {
      UserPrivate born(DateTime dob) =>
          complete(dateOfBirthUtc: dob).copyWith(guardian: () => null);
      // 18 tomorrow: still 17 today.
      expect(blank(born(DateTime.utc(2008, 10, 28))), [S.fieldGuardian]);
      // 18 today.
      expect(blank(born(DateTime.utc(2008, 10, 27))), isEmpty);
    });

    test('Issue 340: a blank date of birth lists itself, not the guardian', () {
      final user = complete().copyWith(
        dateOfBirthUtc: () => null,
        guardian: () => null,
      );
      expect(blank(user), [S.fieldDateOfBirth]);
    });

    test('Issue 340: the middle name and membership date are never listed', () {
      final user = complete().copyWith(
        middleName: () => null,
        membershipDateUtc: () => null,
      );
      expect(blank(user), isEmpty);
    });
  });
}
