import 'package:club_sdk_2/club_sdk_2.dart'
    show AuthSource, Gender, SdkErrorCode, ServerException;
import 'package:ui_lib/ui_lib.dart'
    show PhoneNumber, SignupGender, SignupSubmitResult;

/// Form → SDK adapter for `SignupForm` (which lives SDK-free in `ui_lib`).
abstract final class SignupFormSubmit {
  /// Shown under the form when registration fails for a reason no field
  /// explains.
  static const String createFailedMessage =
      'Could not create account. Please try again.';

  /// Registers the account the form describes and reports the outcome in the
  /// form's own terms.
  ///
  /// The phone is stored in international format, completed with
  /// [defaultCountryCode] when typed without a country code (#31).
  static Future<SignupSubmitResult> create({
    required AuthSource auth,
    required String defaultCountryCode,
    required String username,
    required String password,
    required String email,
    required String phone,
    required DateTime dateOfBirthUtc,
    required SignupGender gender,
    String? firstName,
    String? middleName,
    String? lastName,
  }) async {
    try {
      await auth.register(
        username: username,
        email: email,
        password: password,
        phone: PhoneNumber.toInternational(
          phone,
          defaultCountryCode: defaultCountryCode,
        ),
        dateOfBirthUtc: dateOfBirthUtc,
        gender: toSdkGender(gender),
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
      );
      return const SignupSubmitResult();
    } on ServerException catch (e) {
      return resultFor(e.code);
    } on Object catch (_) {
      return const SignupSubmitResult(formError: createFailedMessage);
    }
  }

  /// The form result for a refused registration: a message on the field the
  /// server's [code] names, or [createFailedMessage].
  static SignupSubmitResult resultFor(String? code) {
    if (code == SdkErrorCode.duplicateUsername) {
      return const SignupSubmitResult(
        fieldErrors: {'username': 'That username is already taken.'},
      );
    }
    if (code == SdkErrorCode.duplicateEmail) {
      return const SignupSubmitResult(
        fieldErrors: {'email': 'That email is already registered.'},
      );
    }
    return const SignupSubmitResult(formError: createFailedMessage);
  }

  /// The SDK gender for the form's [gender].
  static Gender toSdkGender(SignupGender gender) {
    return switch (gender) {
      SignupGender.male => Gender.male,
      SignupGender.female => Gender.female,
      SignupGender.other => Gender.other,
      SignupGender.preferNotToSay => Gender.preferNotToSay,
    };
  }
}
