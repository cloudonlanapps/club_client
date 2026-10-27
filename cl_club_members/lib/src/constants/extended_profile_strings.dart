/// What the extended profile's sections show (club_client#320): their
/// titles, the hints of an empty section, the rows of the read view and
/// the messages of a save.
abstract final class ExtendedProfileStrings {
  /// Title of the sports details section.
  static const String sportsDetailsTitle = 'Sports details';

  /// Title of the background section.
  static const String backgroundTitle = 'Background';

  /// Title of the guardian section.
  static const String guardianTitle = 'Guardian';

  /// Hint of an empty sports details section.
  static const String sportsDetailsEmptyHint = 'Tap to add sports details';

  /// Hint of an empty background section.
  static const String backgroundEmptyHint = 'Tap to add background';

  /// Hint of an empty guardian section.
  static const String guardianEmptyHint = 'Tap to add a guardian';

  /// Read row: the club or district.
  static const String clubDistrict = 'Club / District';

  /// Read row: the preferred positions.
  static const String preferredPositions = 'Preferred positions';

  /// Read row: the past experience.
  static const String pastExperience = 'Past experience';

  /// Read row: the nationality.
  static const String nationality = 'Nationality';

  /// Read row: the preferred languages.
  static const String preferredLanguages = 'Preferred languages';

  /// Read row: the guardian's name.
  static const String guardianName = 'Name';

  /// Read row: the guardian's relation.
  static const String guardianRelation = 'Relation';

  /// Read row: the guardian's phone.
  static const String guardianPhone = 'Phone';

  /// Read row: the membership date.
  static const String membershipDate = 'Membership date';

  /// The membership date of a member who has none.
  static const String notSet = 'Not set';

  /// Saved the sports details.
  static const String sportsDetailsSaved = 'Sports details updated.';

  /// Saved the background.
  static const String backgroundSaved = 'Background updated.';

  /// Saved the guardian.
  static const String guardianSaved = 'Guardian updated.';

  /// Saved the membership date.
  static const String membershipDateSaved = 'Membership date updated.';

  /// A position or language the club does not offer; shown on that field.
  static const String optionRefused =
      'The club does not offer this choice. Pick another.';

  /// A membership date the server does not take; shown on that field.
  static const String membershipDateRefused =
      'That date was not accepted. Pick it again.';

  /// A membership date sent by someone who is not an admin.
  static const String membershipDateProtected =
      'Only an admin can change this.';
}
