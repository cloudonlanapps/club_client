import 'package:cl_member_auth/src/models/signup_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show SignupGender;

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

Future<String?> _registeredPhone(String typed, String code) async {
  final auth = _RecordingAuth();
  final result = await SignupFormSubmit.create(
    auth: auth,
    defaultCountryCode: code,
    username: 'robin',
    password: 'not-a-real-password',
    email: 'robin@example.test',
    phone: typed,
    dateOfBirthUtc: DateTime.utc(2010, 3, 4),
    gender: SignupGender.female,
  );
  expect(result.isSuccess, isTrue);
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
      final result = await SignupFormSubmit.create(
        auth: _RecordingAuth(
          refusal: const ServerException(
            statusCode: 409,
            code: SdkErrorCode.duplicateEmail,
            message: 'duplicate',
          ),
        ),
        defaultCountryCode: '91',
        username: 'robin',
        password: 'not-a-real-password',
        email: 'robin@example.test',
        phone: '9876543210',
        dateOfBirthUtc: DateTime.utc(2010, 3, 4),
        gender: SignupGender.female,
      );

      expect(result.fieldErrors, {
        'email': 'That email is already registered.',
      });
    });
  });
}
