import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, SdkException;

import '../utils/login_error_messages.dart';

/// SDK → form adapter for `LoginForm` (which lives SDK-free in
/// `cl_club_forms`).
abstract final class LoginFormSubmit {
  /// What the form shows inline for a sign-in that failed with [error]: the
  /// server refusing the username and password together, which names
  /// neither field. Null when the failure is not about what was typed; the
  /// host then reports it in a toast.
  static String? formErrorFor(Object error) =>
      error is SdkException && error.code == SdkErrorCode.invalidCredentials
      ? LoginErrorMessages.invalidCredentials
      : null;
}
