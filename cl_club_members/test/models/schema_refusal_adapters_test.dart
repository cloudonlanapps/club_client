import 'package:cl_club_forms/cl_club_forms.dart'
    show
        AgeEligibilityFormFields,
        GenderEligibilityFormFields,
        GroupFormFields,
        UserFormFields;
import 'package:cl_club_members/src/models/group_form_helpers.dart';
import 'package:cl_club_members/src/models/user_form_helpers.dart';
import 'package:cl_club_members/src/utils/member_write_messages.dart';
import 'package:cl_club_members/src/utils/profile_save_error_message.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// A schema rejection (422) naming [fields], each with the reason "refused".
ServerException _rejection(List<List<Object>> fields) => ServerException(
  statusCode: 422,
  code: SdkErrorCode.validationError,
  message: 'refused',
  details: {
    ServerException.refusedFieldsKey: [
      for (final loc in fields) {'loc': loc, 'msg': 'refused'},
    ],
  },
);

ServerException _refused(String code) =>
    ServerException(statusCode: 409, code: code, message: 'raw');

void main() {
  group('Issue 114: a schema rejection shows on the user field it names', () {
    test('Issue 114: user create puts it on each field the form holds', () {
      final errors = UserFormSubmit.fieldErrorsFor(
        _rejection([
          ['body', 'username'],
          ['body', 'email'],
          ['body', 'passwordHash'],
          ['body', 'phone'],
          ['body', 'dateOfBirthUtc'],
          ['body', 'gender'],
          ['body', 'firstName'],
          ['body', 'middleName'],
          ['body', 'lastName'],
          ['body', 'emergencyContact'],
          ['body', 'medicalInfo'],
          ['body', 'address', 'addrLine1'],
          ['body', 'address', 'addrLine2'],
          ['body', 'address', 'city'],
          ['body', 'address', 'state'],
          ['body', 'address', 'pincode'],
        ]),
      );

      expect(errors.keys, {
        UserFormFields.usernameId,
        UserFormFields.emailId,
        UserFormFields.passwordId,
        UserFormFields.phoneId,
        UserFormFields.dateOfBirthUtcId,
        UserFormFields.genderId,
        UserFormFields.firstNameId,
        UserFormFields.middleNameId,
        UserFormFields.lastNameId,
        UserFormFields.emergencyContactNameId,
        UserFormFields.medicalInfoId,
        UserFormFields.addrLine1Id,
        UserFormFields.addrLine2Id,
        UserFormFields.cityId,
        UserFormFields.stateId,
        UserFormFields.pincodeId,
      });
      expect(errors[UserFormFields.pincodeId], 'Refused');
    });

    test('Issue 114: user create keeps its own words for a taken email, and '
        'names no field for a rejection of none of its fields', () {
      expect(
        UserFormSubmit.fieldErrorsFor(_refused(SdkErrorCode.duplicateEmail)),
        {UserFormFields.emailId: MemberWriteMessages.emailRegistered},
      );
      expect(
        UserFormSubmit.fieldErrorsFor(
          _rejection([
            ['body'],
            ['body', 'isGuest'],
          ]),
        ),
        isEmpty,
      );
    });

    test('Issue 114: personal details puts it on the names, the nickname, '
        'the gender and the date of birth', () {
      expect(
        UserFormSubmit.personalDetailsFieldErrors(
          _rejection([
            ['body', 'firstName'],
            ['body', 'nickname'],
            ['body', 'gender'],
            ['body', 'dateOfBirthUtc'],
          ]),
        ).keys,
        {
          UserFormFields.firstNameId,
          UserFormFields.nicknameId,
          UserFormFields.genderId,
          UserFormFields.dateOfBirthUtcId,
        },
      );
    });

    test('Issue 114: contact puts it on the email, the phone, the emergency '
        'contact and the medical notes, and keeps its words for a taken '
        'email', () {
      expect(
        UserFormSubmit.contactFieldErrors(
          _rejection([
            ['body', 'email'],
            ['body', 'phone'],
            ['body', 'emergencyContact'],
            ['body', 'medicalInfo'],
          ]),
        ).keys,
        {
          UserFormFields.emailId,
          UserFormFields.phoneId,
          UserFormFields.emergencyContactNameId,
          UserFormFields.medicalInfoId,
        },
      );
      expect(
        UserFormSubmit.contactFieldErrors(
          _refused(SdkErrorCode.duplicateEmail),
        ),
        {
          UserFormFields.emailId: profileSaveErrorMessage(
            _refused(SdkErrorCode.duplicateEmail),
          ),
        },
      );
    });

    test('Issue 114: address puts it on the line, the city, the state and '
        'the pincode', () {
      expect(
        UserFormSubmit.addressFieldErrors(
          _rejection([
            ['body', 'address', 'addrLine1'],
            ['body', 'address', 'city'],
            ['body', 'address', 'state'],
            ['body', 'address', 'pincode'],
          ]),
        ).keys,
        {
          UserFormFields.addrLine1Id,
          UserFormFields.cityId,
          UserFormFields.stateId,
          UserFormFields.pincodeId,
        },
      );
      expect(
        UserFormSubmit.addressFieldErrors(_refused(SdkErrorCode.conflict)),
        isEmpty,
      );
    });
  });

  group('Issue 114: a schema rejection shows on the group field it names', () {
    final rejection = _rejection([
      ['body', 'name'],
      ['body', 'description'],
      ['body', 'genders'],
      ['body', 'semiAuto'],
      ['body', 'minAge', 'years'],
      ['body', 'maxAge'],
      ['body', 'strictAge'],
    ]);
    const fieldIds = {
      GroupFormFields.nameId,
      GroupFormFields.descriptionId,
      GenderEligibilityFormFields.gendersId,
      GroupFormFields.modeId,
      AgeEligibilityFormFields.minAgeYearsId,
      AgeEligibilityFormFields.maxAgeYearsId,
      AgeEligibilityFormFields.strictAgeId,
    };

    test('Issue 114: group create puts it on each field the form holds', () {
      final refusal = GroupFormSubmit.createRefusal(rejection);

      expect(refusal?.fieldErrors.keys, fieldIds);
      expect(refusal?.formError, isNull);
    });

    test('Issue 114: group eligibility puts it on each field the form '
        'holds', () {
      final refusal = GroupFormSubmit.eligibilityRefusal(rejection);

      expect(refusal?.fieldErrors.keys, fieldIds);
      expect(refusal?.formError, isNull);
    });

    test('Issue 114: a rejection that names none of its fields is no '
        'refusal of the form', () {
      final none = _rejection([
        ['body'],
      ]);

      expect(GroupFormSubmit.createRefusal(none), isNull);
      expect(GroupFormSubmit.eligibilityRefusal(none), isNull);
    });

    test('Issue 114: group rename shows the reason on the name', () {
      expect(
        GroupFormSubmit.renameRefusal(
          _rejection([
            ['body', 'name'],
          ]),
          fallback: 'Could not rename group.',
        ),
        'Refused',
      );
      expect(
        GroupFormSubmit.renameRefusal(
          Exception('offline'),
          fallback: 'Could not rename group.',
        ),
        'Could not rename group.',
      );
    });
  });
}
