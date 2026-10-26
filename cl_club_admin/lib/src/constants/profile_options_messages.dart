/// What the Profile options section of the club details screen shows
/// (club_client#320).
abstract final class ProfileOptionsMessages {
  /// Title of the section.
  static const String title = 'Profile options';

  /// What the options are for, above their rows or the form.
  static const String description =
      'The positions and languages members choose from in their profile. '
      'A position has a name in each language a form may print it in.';

  /// Hint of a club with no options yet.
  static const String emptyHint = 'Tap to add positions and languages';

  /// Read row: the positions.
  static const String positions = 'Positions';

  /// Read row: the languages.
  static const String languages = 'Languages';

  /// Joins a position's labels in a read row.
  static const String labelSeparator = ' · ';

  /// Joins the positions, and the languages, in a read row.
  static const String listSeparator = ', ';

  /// A list with nothing in it.
  static const String none = 'None';

  /// Saved the options.
  static const String saved = 'Profile options updated.';

  /// A save that failed, or was refused naming nothing the form holds.
  static const String saveFailed =
      "Couldn't save the profile options. Try again.";
}
