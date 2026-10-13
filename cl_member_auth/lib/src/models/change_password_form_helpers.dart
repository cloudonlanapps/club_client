import 'package:cl_club_forms/cl_club_forms.dart' show ChangePasswordFormFields;
import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import '../constants/auth_view_strings.dart';

/// SDK → form adapter for `ChangePasswordForm` (which lives SDK-free in
/// `cl_club_forms`).
abstract final class ChangePasswordFormSubmit {
  /// The server's name for the current password.
  static const String serverCurrentPassword = 'currentPassword';

  /// The server's name for the new password.
  static const String serverNewPassword = 'newPassword';

  /// The fields of the change-password request, as the server names them,
  /// each with the id of the form field that holds it.
  static const Map<String, String> schemaFieldIds = {
    serverCurrentPassword: ChangePasswordFormFields.currentId,
    serverNewPassword: ChangePasswordFormFields.nextId,
  };

  /// What the form shows for a refused change: a current password the
  /// server does not accept shows on its field, and a schema rejection on
  /// the field it names. Empty when [error] names no field; the host then
  /// shows a toast.
  static Map<String, String> fieldErrorsFor(Object error) {
    if (error is ServerException &&
        error.code == SdkErrorCode.invalidCredentials) {
      return const {
        ChangePasswordFormFields.currentId:
            AuthViewStrings.currentPasswordIncorrect,
      };
    }
    return schemaFieldErrors(error, schemaFieldIds);
  }
}
