import '../signup/signup_gender.dart';
import 'user_form_fields.dart';

/// Shared validators for user-shaped forms (`UserForm`, `SignupForm`).
///
/// Each method returns `null` when valid, or an error message string.
/// SDK-free: gender is validated against the form-local [SignupGender].
class UserFormValidators {
  const UserFormValidators._();

  static final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]+$');

  /// Shown when the password is not typed a second time.
  static const String confirmPasswordRequired = 'Please confirm the password';

  /// Shown when the two passwords differ.
  static const String passwordsDiffer = 'Passwords do not match';

  /// Shown when a new account's username was not checked for availability.
  static const String availabilityCheckRequired =
      'Run the availability check before creating the account.';

  static String? username(String value) {
    final t = value.trim();
    if (t.isEmpty) return 'Username is required';
    if (t.length < UserFormFields.usernameMinLength) {
      return 'At least 3 characters';
    }
    if (!_usernamePattern.hasMatch(t)) {
      return 'Only lowercase letters, digits, and _';
    }
    return null;
  }

  static String? email(String value) {
    final t = value.trim();
    if (t.isEmpty) return 'Email is required';
    if (!t.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < UserFormFields.passwordMinLength) {
      return 'At least 8 characters';
    }
    return null;
  }

  /// The password typed again: required.
  static String? confirmPassword(String value) =>
      value.isEmpty ? confirmPasswordRequired : null;

  /// The rule across the two passwords: they must be the same.
  static String? passwordsMatch(String? password, String? confirm) =>
      (password ?? '') == (confirm ?? '') ? null : passwordsDiffer;

  /// Phone is required and must be at least 10 characters.
  static String? phone(String value) {
    final t = value.trim();
    if (t.isEmpty) return 'Phone number is required';
    if (t.length < UserFormFields.phoneMinLength) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Phone is optional, but if provided must be at least 10 characters.
  static String? phoneOptional(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    if (t.length < UserFormFields.phoneMinLength) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Gender must be selected.
  static String? gender(SignupGender? value) {
    if (value == null) return 'Gender is required';
    return null;
  }

  /// Date of birth must be selected.
  static String? dateOfBirth(DateTime? value) {
    if (value == null) return 'Date of birth is required';
    return null;
  }

  /// Pincode is optional, but if provided must be exactly 6 digits.
  static String? pincode(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^\d{6}$').hasMatch(t)) return 'Enter a valid 6-digit pincode';
    return null;
  }

  /// At least one of firstName or lastName must be non-empty.
  static String? atLeastOneName(String? firstName, String? lastName) {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    if (f.isEmpty && l.isEmpty) {
      return 'First name or last name is required';
    }
    return null;
  }
}
