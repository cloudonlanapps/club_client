// Issue 320: the adapter of the extended profile's section forms — what
// each section sends, and where a refused save shows.
import 'package:cl_club_forms/cl_club_forms.dart'
    show ProfilePositionOption, UserFormFields;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/models/user_extended_profile_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which fields an update was given, and their values.
class _RecordingUsers extends ClUsersMasterNotifier {
  final List<Map<String, Object?>> sent = [];

  @override
  Future<Map<String, UserInfo>> build() async => {};

  @override
  Future<UserPrivate> updateUser(
    String username, {
    String? email,
    String? Function()? firstName,
    String? Function()? middleName,
    String? Function()? lastName,
    String? Function()? phone,
    DateTime? Function()? dateOfBirthUtc,
    String? Function()? bio,
    String? Function()? achievements,
    String? Function()? emergencyContact,
    String? Function()? medicalNotes,
    String? Function()? nickname,
    bool? useNamePublicly,
    Gender? Function()? gender,
    Address? Function()? address,
    bool? isPublicProfile,
    String? Function()? clubDistrict,
    List<String>? preferredPositions,
    String? Function()? pastExperience,
    String? Function()? nationality,
    List<String>? preferredLanguages,
    Guardian? Function()? guardian,
    DateTime? Function()? membershipDateUtc,
  }) async {
    final anyOther = [
      email,
      firstName,
      middleName,
      lastName,
      phone,
      dateOfBirthUtc,
      bio,
      achievements,
      emergencyContact,
      medicalNotes,
      nickname,
      useNamePublicly,
      gender,
      address,
      isPublicProfile,
    ].any((v) => v != null);
    sent.add({
      if (anyOther) 'other': true,
      if (clubDistrict != null) 'clubDistrict': clubDistrict(),
      'preferredPositions': ?preferredPositions,
      if (pastExperience != null) 'pastExperience': pastExperience(),
      if (nationality != null) 'nationality': nationality(),
      'preferredLanguages': ?preferredLanguages,
      if (guardian != null) 'guardian': guardian(),
      if (membershipDateUtc != null) 'membershipDateUtc': membershipDateUtc(),
    });
    return _member();
  }
}

UserPrivate _member() => UserPrivate(
  username: 'robin',
  displayName: 'Robin',
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024, 6, 15),
  clubDistrict: 'Pune',
  preferredPositions: const ['Forward', 'Goalie'],
  pastExperience: 'School team',
  nationality: 'Indian',
  preferredLanguages: const ['Marathi'],
  guardian: const Guardian(name: 'Asha', relation: 'Mother', phone: '+91 98'),
  membershipDateUtc: DateTime.utc(2025, 4, 2),
);

void main() {
  group('Issue 320: buildUserExtendedProfileFormInitialValues', () {
    test('Issue 320: reads every extended field of the member, the first '
        'of each list', () {
      expect(buildUserExtendedProfileFormInitialValues(_member()), {
        UserFormFields.clubDistrictId: 'Pune',
        UserFormFields.preferredPositionsId: 'Forward',
        UserFormFields.pastExperienceId: 'School team',
        UserFormFields.nationalityId: 'Indian',
        UserFormFields.preferredLanguagesId: 'Marathi',
        UserFormFields.guardianNameId: 'Asha',
        UserFormFields.guardianRelationId: 'Mother',
        UserFormFields.guardianPhoneId: '+91 98',
      });
    });

    test('Issue 320: a blank member reads as empty texts', () {
      final blank = UserPrivate(
        username: 'x',
        displayName: 'x',
        status: UserStatus.registered,
        isSuperAdmin: false,
        roles: const UserRoles(),
        createdAtUtc: DateTime.utc(2024),
      );
      expect(
        buildUserExtendedProfileFormInitialValues(blank).values.toSet(),
        {''},
      );
    });
  });

  group('Issue 320: profilePositionOptions', () {
    test('Issue 320: each position shows its English label, else its '
        'value', () {
      const options = ProfileOptions(
        positions: [
          ProfilePosition(value: 'Forward', label: {'en': 'Fwd', 'mr': 'x'}),
          ProfilePosition(value: 'Goalie', label: {'mr': 'y'}),
        ],
      );
      expect(profilePositionOptions(options), const [
        ProfilePositionOption(value: 'Forward', label: 'Fwd'),
        ProfilePositionOption(value: 'Goalie', label: 'Goalie'),
      ]);
    });
  });

  group('Issue 320: UserExtendedProfileFormSubmit sends only its section', () {
    test('Issue 320: updateSportsDetails sends its three fields, blank as '
        'null', () async {
      final users = _RecordingUsers();
      await UserExtendedProfileFormSubmit.updateSportsDetails(
        values: const {
          UserFormFields.clubDistrictId: ' Mumbai ',
          UserFormFields.preferredPositionsId: 'Goalie',
          UserFormFields.pastExperienceId: '',
        },
        username: 'robin',
        notifier: users,
      );
      expect(users.sent.single, {
        'clubDistrict': 'Mumbai',
        'preferredPositions': ['Goalie'],
        'pastExperience': null,
      });
    });

    test('Issue 320: updateBackground sends nationality and language '
        'alone', () async {
      final users = _RecordingUsers();
      await UserExtendedProfileFormSubmit.updateBackground(
        values: const {
          UserFormFields.nationalityId: 'Indian',
          UserFormFields.preferredLanguagesId: '',
        },
        username: 'robin',
        notifier: users,
      );
      expect(users.sent.single, {
        'nationality': 'Indian',
        'preferredLanguages': <String>[],
      });
    });

    test('Issue 320: updateGuardian sends the guardian, its phone in '
        'international form', () async {
      final users = _RecordingUsers();
      await UserExtendedProfileFormSubmit.updateGuardian(
        values: const {
          UserFormFields.guardianNameId: 'Asha',
          UserFormFields.guardianRelationId: ' Mother ',
          UserFormFields.guardianPhoneId: '9876543210',
        },
        username: 'robin',
        notifier: users,
        defaultCountryCode: '91',
      );
      expect(users.sent.single, {
        'guardian': const Guardian(
          name: 'Asha',
          relation: 'Mother',
          phone: '+919876543210',
        ),
      });
    });

    test('Issue 320: a guardian left blank is cleared', () async {
      final users = _RecordingUsers();
      await UserExtendedProfileFormSubmit.updateGuardian(
        values: const {
          UserFormFields.guardianNameId: '',
          UserFormFields.guardianRelationId: '',
          UserFormFields.guardianPhoneId: '',
        },
        username: 'robin',
        notifier: users,
        defaultCountryCode: '91',
      );
      expect(users.sent.single, {'guardian': null});
    });

    test('Issue 320: updateMembershipDate sends the day at UTC midnight '
        'alone', () async {
      final users = _RecordingUsers();
      await UserExtendedProfileFormSubmit.updateMembershipDate(
        values: {UserFormFields.membershipDateUtcId: DateTime(2025, 5, 9)},
        username: 'robin',
        notifier: users,
      );
      expect(users.sent.single, {
        'membershipDateUtc': DateTime.utc(2025, 5, 9),
      });
    });
  });

  group('Issue 320: UserExtendedProfileFormSubmit.fieldErrorsFor', () {
    test('Issue 320: a position the club does not offer shows on the '
        'position', () {
      const error = InvalidProfileOptionException(
        message: 'raw',
        field: 'preferredPositions',
        value: 'Winger',
      );
      expect(UserExtendedProfileFormSubmit.fieldErrorsFor(error), {
        UserFormFields.preferredPositionsId:
            ExtendedProfileStrings.optionRefused,
      });
    });

    test('Issue 320: a language the club does not offer shows on the '
        'language', () {
      const error = InvalidProfileOptionException(
        message: 'raw',
        field: 'preferredLanguages',
        value: 'Tamil',
      );
      expect(UserExtendedProfileFormSubmit.fieldErrorsFor(error), {
        UserFormFields.preferredLanguagesId:
            ExtendedProfileStrings.optionRefused,
      });
    });

    test("Issue 320: a schema refusal of the guardian's phone shows on "
        'that field', () {
      const error = ServerException(
        statusCode: 422,
        code: SdkErrorCode.validationError,
        message: 'raw',
        details: {
          ServerException.refusedFieldsKey: [
            {
              'loc': ['body', 'guardian', 'phone'],
              'msg': 'String should have at most 20 characters',
            },
          ],
        },
      );
      expect(
        UserExtendedProfileFormSubmit.fieldErrorsFor(error).keys,
        [UserFormFields.guardianPhoneId],
      );
    });

    test('Issue 320: a membership date the server does not take shows on '
        'it', () {
      const error = ServerException(
        statusCode: 422,
        code: SdkErrorCode.invalidDobNotUtcMidnight,
        message: 'raw',
      );
      expect(UserExtendedProfileFormSubmit.fieldErrorsFor(error), {
        UserFormFields.membershipDateUtcId:
            ExtendedProfileStrings.membershipDateRefused,
      });
    });

    test('Issue 320: a refusal that names no field gives nothing', () {
      const error = ServerException(
        statusCode: 409,
        code: 'SOMETHING',
        message: 'raw',
      );
      expect(UserExtendedProfileFormSubmit.fieldErrorsFor(error), isEmpty);
    });
  });
}
