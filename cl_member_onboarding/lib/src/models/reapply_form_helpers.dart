import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Gender, SdkErrorCode, ServerException, UserPrivate;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber;

/// SDK → form: the reapply form's initial values for [user], keyed by
/// [UserFormFields] ids. A field the member never filled has no entry.
Map<String, dynamic> buildReapplyFormInitialValues(UserPrivate user) {
  final gender = user.gender;
  return {
    if (user.firstName != null) UserFormFields.firstNameId: user.firstName,
    if (user.middleName != null) UserFormFields.middleNameId: user.middleName,
    if (user.lastName != null) UserFormFields.lastNameId: user.lastName,
    if (user.dateOfBirthUtc != null)
      UserFormFields.dateOfBirthUtcId: user.dateOfBirthUtc,
    if (gender != null)
      UserFormFields.genderId: ReapplyFormSubmit.toFormGender(gender),
    if (user.phone != null) UserFormFields.phoneId: user.phone,
    UserFormFields.emailId: user.email,
  };
}

/// Form → SDK adapter for the reapply form (`SignupForm`, which lives
/// SDK-free in `cl_club_forms`).
abstract final class ReapplyFormSubmit {
  /// Shown on the email when another account has it.
  static const String emailRegisteredMessage =
      'That email is already registered.';

  /// Shown on the date of birth when the server does not take it.
  static const String dateOfBirthRefusedMessage =
      'That date of birth was not accepted. Pick it again.';

  /// What the form shows for a refused resubmission: a message on the field
  /// the server's answer names, keyed by field id. Empty when [error] names
  /// no field; the host then reports a failed resubmission.
  static Map<String, String> fieldErrorsFor(Object error) {
    if (error is! ServerException) return const {};
    return switch (error.code) {
      SdkErrorCode.duplicateEmail => const {
        UserFormFields.emailId: emailRegisteredMessage,
      },
      SdkErrorCode.invalidDobNotUtcMidnight => const {
        UserFormFields.dateOfBirthUtcId: dateOfBirthRefusedMessage,
      },
      _ => const {},
    };
  }

  /// Resubmits the member's own registration with the form's [values]
  /// (keyed by [UserFormFields] ids, as `SignupFormState.validate` returns
  /// them) and returns the server's answer.
  ///
  /// The phone is stored in international format, completed with
  /// [defaultCountryCode] when typed without a country code (#31).
  static Future<UserPrivate> reapply({
    required ClUsersMasterNotifier notifier,
    required String defaultCountryCode,
    required Map<String, dynamic> values,
  }) {
    return notifier.reapplyForSelf(
      email: values[UserFormFields.emailId] as String,
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

  /// The SDK gender for the form's [gender].
  static Gender toSdkGender(SignupGender gender) {
    return switch (gender) {
      SignupGender.male => Gender.male,
      SignupGender.female => Gender.female,
      SignupGender.other => Gender.other,
      SignupGender.preferNotToSay => Gender.preferNotToSay,
    };
  }

  /// The form's gender for the SDK [gender].
  static SignupGender toFormGender(Gender gender) {
    return switch (gender) {
      Gender.male => SignupGender.male,
      Gender.female => SignupGender.female,
      Gender.other => SignupGender.other,
      Gender.preferNotToSay => SignupGender.preferNotToSay,
    };
  }
}
