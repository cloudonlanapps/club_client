/// The server's names for the fields of a registration, as a schema
/// rejection gives them (club_client#114).
abstract final class SignupServerFields {
  /// The username.
  static const String username = 'username';

  /// The email.
  static const String email = 'email';

  /// The password.
  static const String password = 'password';

  /// The phone number.
  static const String phone = 'phone';

  /// The date of birth.
  static const String dateOfBirthUtc = 'dateOfBirthUtc';

  /// The gender.
  static const String gender = 'gender';

  /// The first name.
  static const String firstName = 'firstName';

  /// The middle name.
  static const String middleName = 'middleName';

  /// The last name.
  static const String lastName = 'lastName';
}
