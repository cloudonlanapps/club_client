import 'dart:io';

import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserFormFields;
import 'package:cl_member_auth/src/models/signup_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the phone a registration carried, or refuses it with [refusal].
class _RecordingAuth extends Fake implements AuthSource {
  _RecordingAuth({this.refusal});

  final ServerException? refusal;
  String? phone;
  Gender? gender;

  @override
  Future<UserInfo> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required DateTime dateOfBirthUtc,
    required Gender gender,
    String? firstName,
    String? middleName,
    String? lastName,
  }) async {
    final refusal = this.refusal;
    if (refusal != null) throw refusal;
    this.phone = phone;
    this.gender = gender;
    return UserInfo(
      username: username,
      displayName: username,
      status: UserStatus.registered,
      isSuperAdmin: false,
      roles: const UserRoles(),
    );
  }
}

/// What `SignupFormState.validate` returns for a filled signup form whose
/// phone is [phone].
Map<String, dynamic> _values(String phone) => {
  UserFormFields.usernameId: 'robin',
  UserFormFields.passwordId: 'not-a-real-password',
  UserFormFields.emailId: 'robin@example.test',
  UserFormFields.phoneId: phone,
  UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
  UserFormFields.genderId: SignupGender.female,
  UserFormFields.firstNameId: null,
  UserFormFields.middleNameId: null,
  UserFormFields.lastNameId: null,
};

Future<String?> _registeredPhone(String typed, String code) async {
  final auth = _RecordingAuth();
  await SignupFormSubmit.create(
    auth: auth,
    defaultCountryCode: code,
    values: _values(typed),
  );
  expect(auth.gender, Gender.female);
  return auth.phone;
}

void main() {
  group('Issue 31: SignupFormSubmit.create stores an international phone', () {
    for (final typed in ['98765 43210', '09876543210']) {
      for (final code in ['91', '44']) {
        test('Issue 31: "$typed" with country code $code', () async {
          expect(await _registeredPhone(typed, code), '+${code}9876543210');
        });
      }
    }

    test('Issue 31: + and 00 keep their own country code', () async {
      expect(await _registeredPhone('+44 98765 43210', '91'), '+449876543210');
      expect(await _registeredPhone('0044 98765-43210', '91'), '+449876543210');
    });

    test('Issue 31: a refusal is still a fixed field message', () async {
      const refusal = ServerException(
        statusCode: 409,
        code: SdkErrorCode.duplicateEmail,
        message: 'duplicate',
      );
      Object? thrown;
      try {
        await SignupFormSubmit.create(
          auth: _RecordingAuth(refusal: refusal),
          defaultCountryCode: '91',
          values: _values('9876543210'),
        );
      } on ServerException catch (error) {
        thrown = error;
      }

      expect(thrown, same(refusal));
      expect(SignupFormSubmit.fieldErrorsFor(refusal), {
        'email': 'That email is already registered.',
      });
    });
  });

  group('Issue 53: SignupFormSubmit names the field a refusal is about', () {
    test('Issue 53: a taken username is a message on the username', () {
      expect(
        SignupFormSubmit.fieldErrorsFor(
          const ServerException(
            statusCode: 409,
            code: SdkErrorCode.duplicateUsername,
            message: 'duplicate',
          ),
        ),
        {UserFormFields.usernameId: SignupFormSubmit.usernameTakenMessage},
      );
    });

    test('Issue 53: any other failure names no field', () {
      expect(SignupFormSubmit.fieldErrorsFor(Exception('offline')), isEmpty);
      expect(
        SignupFormSubmit.fieldErrorsFor(
          const ServerException(
            statusCode: 500,
            code: 'SOMETHING_NEW',
            message: 'raw',
          ),
        ),
        isEmpty,
      );
    });
  });

  group('Issue 59: the signup adapter reads the form by its named ids', () {
    test('Issue 59: no bare string field id is left in the adapter', () {
      final source = File(
        'lib/src/models/signup_form_helpers.dart',
      ).readAsStringSync();
      expect(RegExp(r"""\[['"]\w+['"]\]""").hasMatch(source), isFalse);
      expect(source, contains('UserFormFields.usernameId'));
    });
  });
}
