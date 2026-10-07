import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserFormFields;
import 'package:cl_club_members/src/models/user_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the phone and emergency contact the adapter sends.
class _RecordingNotifier extends ClUsersMasterNotifier {
  final UserPrivate answer = UserPrivate(
    username: 'robin',
    displayName: 'Robin',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(),
    email: 'robin@example.test',
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );

  String? phone;
  String? emergencyContact;

  @override
  Future<UserPrivate> createUser({
    required String username,
    required String email,
    required String passwordHash,
    required String phone,
    required DateTime dateOfBirthUtc,
    required Gender gender,
    String? firstName,
    String? middleName,
    String? lastName,
    String? bio,
    String? achievements,
    String? emergencyContact,
    String? medicalNotes,
    Address? address,
  }) async {
    this.phone = phone;
    this.emergencyContact = emergencyContact;
    return answer;
  }

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
  }) async {
    this.phone = phone?.call();
    this.emergencyContact = emergencyContact?.call();
    return answer;
  }
}

Map<String, dynamic> _createValues({
  required String phone,
  String emergencyContactPhone = '',
}) => {
  UserFormFields.usernameId: 'robin',
  UserFormFields.emailId: 'robin@example.test',
  UserFormFields.useDefaultPasswordId: true,
  UserFormFields.phoneId: phone,
  UserFormFields.dateOfBirthUtcId: DateTime(2010, 3, 4),
  UserFormFields.genderId: SignupGender.female,
  UserFormFields.firstNameId: 'Robin',
  UserFormFields.emergencyContactNameId: emergencyContactPhone.isEmpty
      ? ''
      : 'Sam',
  UserFormFields.emergencyContactRelationId: emergencyContactPhone.isEmpty
      ? null
      : 'Parent',
  UserFormFields.emergencyContactPhoneId: emergencyContactPhone,
};

Map<String, dynamic> _contactValues({
  required String phone,
  String emergencyContactPhone = '',
}) => {
  UserFormFields.emailId: 'robin@example.test',
  UserFormFields.phoneId: phone,
  UserFormFields.emergencyContactNameId: emergencyContactPhone.isEmpty
      ? ''
      : 'Sam',
  UserFormFields.emergencyContactRelationId: emergencyContactPhone.isEmpty
      ? null
      : 'Parent',
  UserFormFields.emergencyContactPhoneId: emergencyContactPhone,
  UserFormFields.medicalInfoId: '',
};

void main() {
  group('Issue 31: UserFormSubmit.create stores international phones', () {
    for (final typed in ['98765 43210', '09876543210']) {
      for (final code in ['91', '44']) {
        test('Issue 31: "$typed" with country code $code', () async {
          final notifier = _RecordingNotifier();

          await UserFormSubmit.create(
            values: _createValues(phone: typed, emergencyContactPhone: typed),
            notifier: notifier,
            defaultCountryCode: code,
          );

          expect(notifier.phone, '+${code}9876543210');
          expect(
            notifier.emergencyContact,
            'Sam (Parent) : +${code}9876543210',
          );
        });
      }
    }

    test('Issue 31: + and 00 keep their own country code', () async {
      final notifier = _RecordingNotifier();

      await UserFormSubmit.create(
        values: _createValues(
          phone: '+44 98765 43210',
          emergencyContactPhone: '0044 98765-43210',
        ),
        notifier: notifier,
        defaultCountryCode: '91',
      );

      expect(notifier.phone, '+449876543210');
      expect(notifier.emergencyContact, 'Sam (Parent) : +449876543210');
    });

    test('Issue 31: no emergency contact stays absent', () async {
      final notifier = _RecordingNotifier();

      await UserFormSubmit.create(
        values: _createValues(phone: '9876543210'),
        notifier: notifier,
        defaultCountryCode: '91',
      );

      expect(notifier.emergencyContact, isNull);
    });
  });

  group('Issue 31: UserFormSubmit.updateContact stores international '
      'phones', () {
    for (final typed in ['98765 43210', '09876543210']) {
      for (final code in ['91', '44']) {
        test('Issue 31: "$typed" with country code $code', () async {
          final notifier = _RecordingNotifier();

          await UserFormSubmit.updateContact(
            values: _contactValues(phone: typed, emergencyContactPhone: typed),
            username: 'robin',
            notifier: notifier,
            defaultCountryCode: code,
          );

          expect(notifier.phone, '+${code}9876543210');
          expect(
            notifier.emergencyContact,
            'Sam (Parent) : +${code}9876543210',
          );
        });
      }
    }

    test('Issue 31: + and 00 keep their own country code', () async {
      final notifier = _RecordingNotifier();

      await UserFormSubmit.updateContact(
        values: _contactValues(
          phone: '0044 98765 43210',
          emergencyContactPhone: '+44 (98765) 43210',
        ),
        username: 'robin',
        notifier: notifier,
        defaultCountryCode: '91',
      );

      expect(notifier.phone, '+449876543210');
      expect(notifier.emergencyContact, 'Sam (Parent) : +449876543210');
    });

    test(
      'Issue 31: a cleared phone and emergency contact stay cleared',
      () async {
        final notifier = _RecordingNotifier();

        await UserFormSubmit.updateContact(
          values: _contactValues(phone: ''),
          username: 'robin',
          notifier: notifier,
          defaultCountryCode: '91',
        );

        expect(notifier.phone, isNull);
        expect(notifier.emergencyContact, isNull);
      },
    );
  });

  group('Issue 59: the user adapter speaks the forms by their named ids', () {
    test('Issue 59: the initial values carry every id the user forms '
        'read', () {
      final values = buildUserFormInitialValues(null);

      expect(
        values.keys.toSet(),
        {
          ...UserFormFields.userIds,
        }..removeAll([
          UserFormFields.useDefaultPasswordId,
          UserFormFields.assignAdminId,
          UserFormFields.assignCoachId,
        ]),
      );
    });

    test('Issue 59: no bare string field id is left in the adapter', () {
      final source = File(
        'lib/src/models/user_form_helpers.dart',
      ).readAsStringSync();
      expect(RegExp(r"""\[['"]\w+['"]\]""").hasMatch(source), isFalse);
      expect(RegExp(r"""maybe\(['"]""").hasMatch(source), isFalse);
      expect(RegExp(r"""containsKey\(['"]""").hasMatch(source), isFalse);
    });
  });
}
