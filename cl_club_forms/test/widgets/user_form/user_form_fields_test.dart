import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/user_form/indian_states.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 61: UserFormFields', () {
    test('Issue 61: no two ids are the same', () {
      expect(
        UserFormFields.userIds.toSet(),
        hasLength(UserFormFields.userIds.length),
      );
      expect(
        UserFormFields.signupIds.toSet(),
        hasLength(UserFormFields.signupIds.length),
      );
    });

    test('Issue 61: the three sections share no field', () {
      final personal = UserFormFields.personalDetailsIds.toSet();
      final contact = UserFormFields.contactIds.toSet();
      final address = UserFormFields.addressIds.toSet();

      expect(personal.intersection(contact), isEmpty);
      expect(personal.intersection(address), isEmpty);
      expect(contact.intersection(address), isEmpty);
    });

    test('Issue 61: the personal details are the names, the two public '
        'flags, gender and date of birth', () {
      expect(UserFormFields.personalDetailsIds, [
        UserFormFields.firstNameId,
        UserFormFields.middleNameId,
        UserFormFields.lastNameId,
        UserFormFields.nicknameId,
        UserFormFields.useNamePubliclyId,
        UserFormFields.isPublicProfileId,
        UserFormFields.genderId,
        UserFormFields.dateOfBirthUtcId,
      ]);
    });

    test('Issue 61: the contact section is email, phone, the emergency '
        'contact and the medical notes', () {
      expect(UserFormFields.contactIds, [
        UserFormFields.emailId,
        UserFormFields.phoneId,
        UserFormFields.emergencyContactNameId,
        UserFormFields.emergencyContactRelationId,
        UserFormFields.emergencyContactPhoneId,
        UserFormFields.medicalInfoId,
      ]);
    });

    test('Issue 61: the address section is its five fields', () {
      expect(UserFormFields.addressIds, [
        UserFormFields.addrLine1Id,
        UserFormFields.addrLine2Id,
        UserFormFields.cityId,
        UserFormFields.stateId,
        UserFormFields.pincodeId,
      ]);
    });

    test('Issue 61: UserForm edits the account fields, the three sections '
        'and the two roles, and nothing else', () {
      expect(UserFormFields.userIds.toSet(), {
        UserFormFields.usernameId,
        UserFormFields.passwordId,
        UserFormFields.confirmPasswordId,
        UserFormFields.useDefaultPasswordId,
        ...UserFormFields.personalDetailsIds,
        ...UserFormFields.contactIds,
        ...UserFormFields.addressIds,
        UserFormFields.assignAdminId,
        UserFormFields.assignCoachId,
      });
    });

    test('Issue 61: SignupForm edits the account, the names, gender, date '
        'of birth, phone and email', () {
      expect(UserFormFields.signupIds, [
        UserFormFields.usernameId,
        UserFormFields.passwordId,
        UserFormFields.confirmPasswordId,
        UserFormFields.firstNameId,
        UserFormFields.middleNameId,
        UserFormFields.lastNameId,
        UserFormFields.genderId,
        UserFormFields.dateOfBirthUtcId,
        UserFormFields.phoneId,
        UserFormFields.emailId,
      ]);
    });

    test('Issue 61: emptyValues names every field that is not a text, each '
        'a field of UserForm, with its starting value', () {
      expect(UserFormFields.emptyValues, {
        UserFormFields.useDefaultPasswordId: true,
        UserFormFields.useNamePubliclyId: false,
        UserFormFields.isPublicProfileId: false,
        UserFormFields.genderId: null,
        UserFormFields.dateOfBirthUtcId: null,
        UserFormFields.emergencyContactRelationId: null,
        UserFormFields.stateId: null,
        UserFormFields.assignAdminId: false,
        UserFormFields.assignCoachId: false,
      });
      expect(
        UserFormFields.emptyValues.keys.toSet().difference(
          UserFormFields.userIds.toSet(),
        ),
        isEmpty,
      );
    });

    test('Issue 61: the limits are the ones the server keeps', () {
      expect(UserFormFields.passwordMinLength, 8);
      expect(UserFormFields.usernameMinLength, 3);
      expect(UserFormFields.phoneMinLength, 10);
      expect(
        ChangePasswordFormFields.passwordMinLength,
        UserFormFields.passwordMinLength,
      );
    });
  });

  group('Issue 61: the options of the user forms', () {
    test('Issue 61: each gender has its label', () {
      expect(
        {for (final gender in SignupGender.values) gender: gender.label},
        {
          SignupGender.male: 'Male',
          SignupGender.female: 'Female',
          SignupGender.other: 'Other',
          SignupGender.preferNotToSay: 'Prefer not to say',
        },
      );
    });

    test('Issue 61: the states are sorted, without a repeat', () {
      expect(indianStates, isNotEmpty);
      expect(indianStates.toSet(), hasLength(indianStates.length));
      expect(indianStates, [...indianStates]..sort());
    });
  });
}
