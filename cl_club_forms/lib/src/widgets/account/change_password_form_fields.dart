/// Field-id constants and limits of the `ShadForm` inside
/// `ChangePasswordForm`.
class ChangePasswordFormFields {
  ChangePasswordFormFields._();

  /// The password the member has now (`String`).
  static const String currentId = 'current';

  /// The password the member wants (`String`).
  static const String nextId = 'next';

  /// The wanted password, typed again (`String`).
  static const String confirmId = 'confirm';

  /// Shortest password the server accepts.
  static const int passwordMinLength = 8;
}
