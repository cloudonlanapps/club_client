import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ChangePasswordFormFields,
        ForgotPasswordFormFields,
        LoginFormFields,
        UserFormFields;
import 'package:cl_member_auth/src/constants/auth_view_strings.dart';
import 'package:cl_member_auth/src/models/change_password_form_helpers.dart';
import 'package:cl_member_auth/src/models/forgot_password_form_helpers.dart';
import 'package:cl_member_auth/src/models/login_form_helpers.dart';
import 'package:cl_member_auth/src/models/signup_form_helpers.dart';
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

void main() {
  group('Issue 114: a schema rejection shows on the field it names', () {
    test('Issue 114: signup puts it on each field the form holds', () {
      final errors = SignupFormSubmit.fieldErrorsFor(
        _rejection([
          ['body', 'username'],
          ['body', 'email'],
          ['body', 'password'],
          ['body', 'phone'],
          ['body', 'dateOfBirthUtc'],
          ['body', 'gender'],
          ['body', 'firstName'],
          ['body', 'middleName'],
          ['body', 'lastName'],
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
      });
      expect(errors[UserFormFields.emailId], 'Refused');
    });

    test('Issue 114: signup keeps its own words for a taken username', () {
      expect(
        SignupFormSubmit.fieldErrorsFor(
          const ServerException(
            statusCode: 409,
            code: SdkErrorCode.duplicateUsername,
            message: 'raw',
          ),
        ),
        {UserFormFields.usernameId: SignupFormSubmit.usernameTakenMessage},
      );
    });

    test('Issue 114: signup leaves a rejection that names none of its '
        'fields to the toast', () {
      expect(
        SignupFormSubmit.fieldErrorsFor(
          _rejection([
            ['body'],
            ['body', 'notAField'],
          ]),
        ),
        isEmpty,
      );
    });

    test('Issue 114: change password puts it on the current and the new '
        'password', () {
      expect(
        ChangePasswordFormSubmit.fieldErrorsFor(
          _rejection([
            ['body', 'currentPassword'],
            ['body', 'newPassword'],
          ]),
        ),
        {
          ChangePasswordFormFields.currentId: 'Refused',
          ChangePasswordFormFields.nextId: 'Refused',
        },
      );
    });

    test('Issue 114: change password keeps its own words for a wrong '
        'current password, and names no field for anything else', () {
      expect(
        ChangePasswordFormSubmit.fieldErrorsFor(
          const ServerException(
            statusCode: 401,
            code: SdkErrorCode.invalidCredentials,
            message: 'raw',
          ),
        ),
        {
          ChangePasswordFormFields.currentId:
              AuthViewStrings.currentPasswordIncorrect,
        },
      );
      expect(
        ChangePasswordFormSubmit.fieldErrorsFor(Exception('offline')),
        isEmpty,
      );
    });

    test('Issue 114: forgot password puts it on the email', () {
      expect(
        ForgotPasswordFormSubmit.fieldErrorsFor(
          _rejection([
            ['body', 'email'],
          ]),
        ),
        {ForgotPasswordFormFields.emailId: 'Refused'},
      );
      expect(
        ForgotPasswordFormSubmit.fieldErrorsFor(Exception('offline')),
        isEmpty,
      );
    });

    test('Issue 114: login puts it on the username and the password', () {
      expect(
        LoginFormSubmit.fieldErrorsFor(
          _rejection([
            ['body', 'username'],
            ['body', 'password'],
          ]),
        ),
        {
          LoginFormFields.usernameId: 'Refused',
          LoginFormFields.passwordId: 'Refused',
        },
      );
      expect(
        LoginFormSubmit.fieldErrorsFor(
          const ServerException(
            statusCode: 401,
            code: SdkErrorCode.invalidCredentials,
            message: 'raw',
          ),
        ),
        isEmpty,
        reason: 'a wrong username or password names neither field',
      );
    });
  });
}
