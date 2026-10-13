import 'package:cl_club_forms/cl_club_forms.dart' show LoginFormFields;
import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, SdkException;

import '../utils/login_error_messages.dart';

/// SDK → form adapter for `LoginForm` (which lives SDK-free in
/// `cl_club_forms`).
abstract final class LoginFormSubmit {
  /// The fields of the sign-in request, as the server names them, each with
  /// the id of the form field that holds it.
  static const Map<String, String> schemaFieldIds = {
    serverUsername: LoginFormFields.usernameId,
    serverPassword: LoginFormFields.passwordId,
  };

  /// The server's name for the username.
  static const String serverUsername = 'username';

  /// The server's name for the password.
  static const String serverPassword = 'password';

  /// What the form shows on its fields for a sign-in that failed with
  /// [error]: a schema rejection on the field it names. Empty when [error]
  /// names no field.
  static Map<String, String> fieldErrorsFor(Object error) =>
      schemaFieldErrors(error, schemaFieldIds);

  /// What the form shows inline for a sign-in that failed with [error]: the
  /// server refusing the username and password together, which names
  /// neither field. Null when the failure is not about what was typed; the
  /// host then reports it in a toast.
  static String? formErrorFor(Object error) =>
      error is SdkException && error.code == SdkErrorCode.invalidCredentials
      ? LoginErrorMessages.invalidCredentials
      : null;
}
