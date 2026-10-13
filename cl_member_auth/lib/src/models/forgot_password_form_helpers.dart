import 'package:cl_club_forms/cl_club_forms.dart' show ForgotPasswordFormFields;
import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;

/// SDK → form adapter for `ForgotPasswordForm` (which lives SDK-free in
/// `cl_club_forms`).
abstract final class ForgotPasswordFormSubmit {
  /// The server's name for the email.
  static const String serverEmail = 'email';

  /// The fields of the reset request, as the server names them, each with
  /// the id of the form field that holds it.
  static const Map<String, String> schemaFieldIds = {
    serverEmail: ForgotPasswordFormFields.emailId,
  };

  /// What the form shows for a refused reset request: a schema rejection on
  /// the field it names. Empty when [error] names no field; the host then
  /// shows a toast.
  static Map<String, String> fieldErrorsFor(Object error) =>
      schemaFieldErrors(error, schemaFieldIds);
}
