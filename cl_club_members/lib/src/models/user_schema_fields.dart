import 'package:cl_club_forms/cl_club_forms.dart' show UserFormFields;

/// The server's names for the fields of a user, as a schema rejection gives
/// them (club_client#114), and the user forms' field for each.
abstract final class UserSchemaFields {
  /// The username.
  static const String username = 'username';

  /// The email.
  static const String email = 'email';

  /// The password an admin sets at creation.
  static const String password = 'passwordHash';

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

  /// The nickname.
  static const String nickname = 'nickname';

  /// Whether the name is shown publicly.
  static const String useNamePublicly = 'useNamePublicly';

  /// Whether a coach's profile is public.
  static const String isPublicProfile = 'isPublicProfile';

  /// The emergency contact, which the server holds as one text.
  static const String emergencyContact = 'emergencyContact';

  /// The medical notes.
  static const String medicalInfo = 'medicalInfo';

  /// The first line of the address.
  static const String addrLine1 = 'address.addrLine1';

  /// The second line of the address.
  static const String addrLine2 = 'address.addrLine2';

  /// The city of the address.
  static const String city = 'address.city';

  /// The state of the address.
  static const String state = 'address.state';

  /// The pincode of the address.
  static const String pincode = 'address.pincode';

  /// Each field of a user, as the server names it, with the id of the form
  /// field that holds it. The emergency contact's three inputs are one text
  /// to the server, so a refusal of it shows on the first.
  static const Map<String, String> fieldIds = {
    username: UserFormFields.usernameId,
    email: UserFormFields.emailId,
    password: UserFormFields.passwordId,
    phone: UserFormFields.phoneId,
    dateOfBirthUtc: UserFormFields.dateOfBirthUtcId,
    gender: UserFormFields.genderId,
    firstName: UserFormFields.firstNameId,
    middleName: UserFormFields.middleNameId,
    lastName: UserFormFields.lastNameId,
    nickname: UserFormFields.nicknameId,
    useNamePublicly: UserFormFields.useNamePubliclyId,
    isPublicProfile: UserFormFields.isPublicProfileId,
    emergencyContact: UserFormFields.emergencyContactNameId,
    medicalInfo: UserFormFields.medicalInfoId,
    addrLine1: UserFormFields.addrLine1Id,
    addrLine2: UserFormFields.addrLine2Id,
    city: UserFormFields.cityId,
    state: UserFormFields.stateId,
    pincode: UserFormFields.pincodeId,
  };
}
