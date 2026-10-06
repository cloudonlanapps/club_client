import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show Gender, UserPrivate;
import 'package:ui_lib/ui_lib.dart' show PhoneNumber, SignupGender;

/// Form → SDK adapter for the reapply form (`SignupForm`, which lives
/// SDK-free in `ui_lib`).
abstract final class ReapplyFormSubmit {
  /// Resubmits the member's own registration with what the form holds and
  /// returns the server's answer.
  ///
  /// The phone is stored in international format, completed with
  /// [defaultCountryCode] when typed without a country code (#31).
  static Future<UserPrivate> reapply({
    required ClUsersMasterNotifier notifier,
    required String defaultCountryCode,
    required String email,
    required String phone,
    required DateTime dateOfBirthUtc,
    required SignupGender gender,
    String? firstName,
    String? middleName,
    String? lastName,
  }) {
    return notifier.reapplyForSelf(
      email: email,
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
