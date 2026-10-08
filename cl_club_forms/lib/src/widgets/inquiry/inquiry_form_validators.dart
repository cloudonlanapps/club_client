import '../common_form_validators.dart';

/// Static, SDK-free validators for `InquiryForm`.
///
/// The form's messages are the club's copy, so each rule takes the message
/// it answers with. Each returns `null` when valid.
class InquiryFormValidators {
  const InquiryFormValidators._();

  /// The visitor's name: required.
  static String? name(String value, {required String requiredMessage}) =>
      value.trim().isEmpty ? requiredMessage : null;

  /// The visitor's email: required, and shaped like an address.
  ///
  /// Deliberately loose: an address the server cannot deliver to is the
  /// server's to find out, and a stricter pattern rejects real addresses.
  static String? email(
    String value, {
    required String requiredMessage,
    required String invalidMessage,
  }) {
    final t = value.trim();
    if (t.isEmpty) return requiredMessage;
    return CommonFormValidators.isEmail(t) ? null : invalidMessage;
  }

  /// The visitor's phone: optional, taken as typed. The host completes it
  /// with the club's country code when it saves.
  static String? phone(String value) => null;

  /// The visitor's message: required only when [required] is true.
  static String? message(
    String value, {
    required bool required,
    required String requiredMessage,
  }) => required && value.trim().isEmpty ? requiredMessage : null;
}
