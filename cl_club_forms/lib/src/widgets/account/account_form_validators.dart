import 'change_password_form_fields.dart';

/// Static, SDK-free validators for the account forms: `LoginForm` and
/// `ChangePasswordForm`.
class AccountFormValidators {
  const AccountFormValidators._();

  /// Shown when no username is typed.
  static const String usernameRequired = 'Username is required';

  /// Shown when no password is typed.
  static const String passwordRequired = 'Password is required';

  /// Shown when the current password is missing.
  static const String currentPasswordRequired = 'Current password is required';

  /// Shown when the new password is missing.
  static const String newPasswordRequired = 'New password is required';

  /// Shown when the new password is too short.
  static const String newPasswordTooShort = 'At least 8 characters';

  /// Shown when the new password is not typed a second time.
  static const String confirmationRequired = 'Please re-type the new password';

  /// Shown when the two new passwords differ.
  static const String newPasswordsDiffer = 'New passwords do not match';

  /// The username of a login: required.
  static String? username(String value) =>
      value.trim().isEmpty ? usernameRequired : null;

  /// The password of a login: required.
  static String? password(String value) =>
      value.isEmpty ? passwordRequired : null;

  /// The current password: required.
  static String? currentPassword(String value) =>
      value.isEmpty ? currentPasswordRequired : null;

  /// The new password: required, at least
  /// [ChangePasswordFormFields.passwordMinLength] characters.
  static String? newPassword(String value) {
    if (value.isEmpty) return newPasswordRequired;
    if (value.length < ChangePasswordFormFields.passwordMinLength) {
      return newPasswordTooShort;
    }
    return null;
  }

  /// The new password typed again: required.
  static String? confirmation(String value) =>
      value.isEmpty ? confirmationRequired : null;

  /// The rule across the two new passwords: they must be the same.
  static String? newPasswordsMatch(String? next, String? confirm) =>
      next == confirm ? null : newPasswordsDiffer;
}
