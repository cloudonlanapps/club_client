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

  /// The club or district (extended profile, club_client#320).
  static const String clubDistrict = 'clubDistrict';

  /// The preferred positions.
  static const String preferredPositions = 'preferredPositions';

  /// The past experience.
  static const String pastExperience = 'pastExperience';

  /// The nationality.
  static const String nationality = 'nationality';

  /// The preferred languages.
  static const String preferredLanguages = 'preferredLanguages';

  /// The guardian, as a whole.
  static const String guardian = 'guardian';

  /// The guardian's name.
  static const String guardianName = 'guardian.name';

  /// The guardian's relation.
  static const String guardianRelation = 'guardian.relation';

  /// The guardian's phone.
  static const String guardianPhone = 'guardian.phone';

  /// The membership date.
  static const String membershipDateUtc = 'membershipDateUtc';

  /// Each field of a user, as the server names it, with the id of the form
  /// field that holds it. The emergency contact's three inputs are one text
  /// to the server, so a refusal of it shows on the first; so does a
  /// refusal of the guardian as a whole.
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
    clubDistrict: UserFormFields.clubDistrictId,
    preferredPositions: UserFormFields.preferredPositionsId,
    pastExperience: UserFormFields.pastExperienceId,
    nationality: UserFormFields.nationalityId,
    preferredLanguages: UserFormFields.preferredLanguagesId,
    guardian: UserFormFields.guardianNameId,
    guardianName: UserFormFields.guardianNameId,
    guardianRelation: UserFormFields.guardianRelationId,
    guardianPhone: UserFormFields.guardianPhoneId,
    membershipDateUtc: UserFormFields.membershipDateUtcId,
  };
}
