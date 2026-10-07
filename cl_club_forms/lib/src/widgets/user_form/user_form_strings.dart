/// Labels and placeholders of the fields the user forms share.
abstract final class UserFormStrings {
  /// Label of the username field.
  static const String username = 'Username';

  /// Hint in the empty username field.
  static const String usernamePlaceholder = 'unique-username';

  /// Label of the password field.
  static const String password = 'Password';

  /// Hint in the empty password field.
  static const String passwordPlaceholder = 'At least 8 characters';

  /// Label of the field the password is typed into again.
  static const String confirmPassword = 'Confirm password';

  /// Hint in the empty confirmation field.
  static const String confirmPasswordPlaceholder = 'Re-type password';

  /// Text beside the tick that gives a created account the default
  /// password.
  static const String useDefaultPassword = 'Use default password';

  /// Label of the action that shows the default password.
  static const String showDefaultPassword = 'Show';

  /// Label of the first-name field.
  static const String firstName = 'First name';

  /// Label of the middle-name field.
  static const String middleName = 'Middle name';

  /// Label of the last-name field.
  static const String lastName = 'Last name';

  /// Label of the nickname field.
  static const String nickname = 'Nickname';

  /// Text of the public-name tick, and label of its read-only value.
  static const String useNamePublicly = 'Show name publicly';

  /// Text of a coach's own public-profile tick.
  static const String isPublicProfile = 'Show my profile publicly';

  /// Text of a coach's own public-name tick.
  static const String useMyNamePublicly = 'Show my name on my public profile';

  /// Read-only value of a ticked flag.
  static const String yes = 'Yes';

  /// Read-only value of an unticked flag.
  static const String no = 'No';

  /// Read-only value of a field nothing was entered for.
  static const String notSet = 'Not set';

  /// Label of the gender field.
  static const String gender = 'Gender';

  /// Hint in the empty gender select.
  static const String genderPlaceholder = 'Select gender';

  /// Hint in the empty gender select where the field is narrow.
  static const String genderShortPlaceholder = 'Select';

  /// Label of the date-of-birth field.
  static const String dateOfBirth = 'Date of birth';

  /// Hint in the empty date-of-birth field.
  static const String dateOfBirthPlaceholder = 'Select date of birth';

  /// Hint in the empty date-of-birth field where the field is narrow.
  static const String dateOfBirthShortPlaceholder = 'Pick date';

  /// How a date of birth reads.
  static const String dateFormat = 'd MMM yyyy';

  /// Label of the phone field.
  static const String phone = 'Phone';

  /// Label of the email field.
  static const String email = 'Email';

  /// Hint in the empty email field.
  static const String emailPlaceholder = 'name@example.com';

  /// Label of the emergency contact's name.
  static const String emergencyContactName = 'Emergency contact name';

  /// Label of the emergency contact's relation.
  static const String emergencyContactRelation = 'Emergency contact relation';

  /// Hint in the empty relation select.
  static const String emergencyContactRelationPlaceholder = 'Select relation';

  /// Label of the emergency contact's phone.
  static const String emergencyContactPhone = 'Emergency contact phone';

  /// Label of the medical notes.
  static const String medicalInfo = 'Medical info';

  /// Heading of the address fields.
  static const String address = 'Address';

  /// Label of the first address line.
  static const String addrLine1 = 'Address line 1';

  /// Label of the second address line.
  static const String addrLine2 = 'Address line 2';

  /// Label of the city field.
  static const String city = 'City';

  /// Label of the state select.
  static const String state = 'State';

  /// Hint in the empty state select.
  static const String statePlaceholder = 'Select state';

  /// Label of the pincode field.
  static const String pincode = 'Pincode';

  /// Heading of the role ticks.
  static const String roles = 'Roles';

  /// Text beside the tick that makes a created account an admin.
  static const String assignAdmin = 'Make this user an Admin';

  /// Text beside the tick that makes a created account a coach.
  static const String assignCoach = 'This user is a coach';
}
