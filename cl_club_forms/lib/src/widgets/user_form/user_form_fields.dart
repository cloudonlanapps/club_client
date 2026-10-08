/// Field-id constants shared by the forms that edit a user: `SignupForm`,
/// `UserForm`, `UserPersonalDetailsForm`, `UserContactForm` and
/// `UserAddressForm`. A field has the same id in every form that shows it.
class UserFormFields {
  UserFormFields._();

  /// The account's username (`String`).
  static const String usernameId = 'username';

  /// The account's password (`String`).
  static const String passwordId = 'password';

  /// The password typed again (`String`).
  static const String confirmPasswordId = 'confirmPassword';

  /// Whether a created account gets the default password (`bool`).
  static const String useDefaultPasswordId = 'useDefaultPassword';

  /// First name (`String`).
  static const String firstNameId = 'firstName';

  /// Middle name (`String`).
  static const String middleNameId = 'middleName';

  /// Last name (`String`).
  static const String lastNameId = 'lastName';

  /// Nickname (`String`).
  static const String nicknameId = 'nickname';

  /// Whether the name shows publicly (`bool`).
  static const String useNamePubliclyId = 'useNamePublicly';

  /// Whether a coach's profile is public (`bool`).
  static const String isPublicProfileId = 'isPublicProfile';

  /// Gender (`SignupGender?`).
  static const String genderId = 'gender';

  /// Date of birth (`DateTime?`).
  static const String dateOfBirthUtcId = 'dateOfBirthUtc';

  /// Phone (`String`).
  static const String phoneId = 'phone';

  /// Email (`String`).
  static const String emailId = 'email';

  /// Emergency contact's name (`String`).
  static const String emergencyContactNameId = 'emergencyContactName';

  /// Emergency contact's relation (`String?`, one of
  /// `UserFormAssembly.emergencyRelations`).
  static const String emergencyContactRelationId = 'emergencyContactRelation';

  /// Emergency contact's phone (`String`).
  static const String emergencyContactPhoneId = 'emergencyContactPhone';

  /// Medical notes (`String`).
  static const String medicalInfoId = 'medicalInfo';

  /// Address line 1 (`String`).
  static const String addrLine1Id = 'addrLine1';

  /// Address line 2 (`String`).
  static const String addrLine2Id = 'addrLine2';

  /// City (`String`).
  static const String cityId = 'city';

  /// State (`String?`, one of `indianStates`).
  static const String stateId = 'state';

  /// Pincode (`String`).
  static const String pincodeId = 'pincode';

  /// Whether a created account is made an admin (`bool`).
  static const String assignAdminId = 'assignAdmin';

  /// Whether a created account is made a coach (`bool`).
  static const String assignCoachId = 'assignCoach';

  /// The fields `UserPersonalDetailsForm` edits.
  static const List<String> personalDetailsIds = [
    firstNameId,
    middleNameId,
    lastNameId,
    nicknameId,
    useNamePubliclyId,
    isPublicProfileId,
    genderId,
    dateOfBirthUtcId,
  ];

  /// The fields `UserContactForm` edits.
  static const List<String> contactIds = [
    emailId,
    phoneId,
    emergencyContactNameId,
    emergencyContactRelationId,
    emergencyContactPhoneId,
    medicalInfoId,
  ];

  /// The fields `UserAddressForm` edits.
  static const List<String> addressIds = [
    addrLine1Id,
    addrLine2Id,
    cityId,
    stateId,
    pincodeId,
  ];

  /// The fields `SignupForm` edits.
  static const List<String> signupIds = [
    usernameId,
    passwordId,
    confirmPasswordId,
    firstNameId,
    middleNameId,
    lastNameId,
    genderId,
    dateOfBirthUtcId,
    phoneId,
    emailId,
  ];

  /// Every field `UserForm` may edit.
  static const List<String> userIds = [
    usernameId,
    passwordId,
    confirmPasswordId,
    useDefaultPasswordId,
    ...personalDetailsIds,
    ...addressIds,
    ...contactIds,
    assignAdminId,
    assignCoachId,
  ];

  /// What a field holds before anything is typed, for the fields that do
  /// not start as an empty text.
  static const Map<String, Object?> emptyValues = {
    useDefaultPasswordId: true,
    useNamePubliclyId: false,
    isPublicProfileId: false,
    genderId: null,
    dateOfBirthUtcId: null,
    emergencyContactRelationId: null,
    stateId: null,
    assignAdminId: false,
    assignCoachId: false,
  };

  /// Shortest password the server accepts.
  static const int passwordMinLength = 8;

  /// Shortest username the server accepts.
  static const int usernameMinLength = 3;
}
