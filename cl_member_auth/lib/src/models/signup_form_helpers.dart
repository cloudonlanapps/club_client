import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserFormFields;
import 'package:club_sdk_2/club_sdk_2.dart'
    show AuthSource, Gender, SdkErrorCode, ServerException;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

/// Form → SDK adapter for `SignupForm` (which lives SDK-free in
/// `cl_club_forms`).
abstract final class SignupFormSubmit {
  /// Shown when registration fails for a reason no field explains.
  static const String createFailedMessage =
      'Could not create account. Please try again.';

  /// Shown on the username when another account has it.
  static const String usernameTakenMessage = 'That username is already taken.';

  /// Shown on the email when another account has it.
  static const String emailRegisteredMessage =
      'That email is already registered.';

  /// Registers the account the form's [values] describe (keyed by
  /// [UserFormFields] ids, as `SignupFormState.validate` returns them).
  /// Throws what the server answers when it refuses.
  ///
  /// The phone is stored in international format, completed with
  /// [defaultCountryCode] when typed without a country code (#31).
  static Future<void> create({
    required AuthSource auth,
    required String defaultCountryCode,
    required Map<String, dynamic> values,
  }) async {
    await auth.register(
      username: values[UserFormFields.usernameId] as String,
      email: values[UserFormFields.emailId] as String,
      password: values[UserFormFields.passwordId] as String,
      phone: PhoneNumber.toInternational(
        values[UserFormFields.phoneId] as String,
        defaultCountryCode: defaultCountryCode,
      ),
      dateOfBirthUtc: values[UserFormFields.dateOfBirthUtcId] as DateTime,
      gender: toSdkGender(values[UserFormFields.genderId] as SignupGender),
      firstName: values[UserFormFields.firstNameId] as String?,
      middleName: values[UserFormFields.middleNameId] as String?,
      lastName: values[UserFormFields.lastNameId] as String?,
    );
  }

  /// What the form shows for a refused registration: a message on the field
  /// the server's answer names, keyed by field id. Empty when [error] names
  /// no field; the host then shows [createFailedMessage].
  static Map<String, String> fieldErrorsFor(Object error) {
    final code = error is ServerException ? error.code : null;
    if (code == SdkErrorCode.duplicateUsername) {
      return const {UserFormFields.usernameId: usernameTakenMessage};
    }
    if (code == SdkErrorCode.duplicateEmail) {
      return const {UserFormFields.emailId: emailRegisteredMessage};
    }
    return const {};
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
