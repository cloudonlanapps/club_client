/// The texts of the club details screen's cards.
abstract final class ClubIdentityMessages {
  /// Title of the card with the club's name, short name, tagline and
  /// inquiry email.
  static const String clubTitle = 'Club';

  /// Title of the card with the public contact block.
  static const String contactTitle = 'Contact';

  /// Title of the card with the postal address.
  static const String addressTitle = 'Address';

  /// Title of the card that adds a language to translate into.
  static const String translationsTitle = 'Translations';

  /// What a translation is, and what adding a language does.
  static const String translationsDescription =
      'Tagline, messages and address take a default text, shown to '
      'everyone, and optionally a text per language. A language '
      'left empty shows the default. A language added here appears on '
      'each of those fields, and is saved with the section it is used in.';

  /// Shown in the Translations card while no language is listed.
  static const String noLanguages =
      'Translations: none yet — every field shows its default text.';

  /// What the list of languages in the Translations card starts with.
  static const String languagesPrefix = 'Translations: ';

  /// Separates two language codes in the Translations card's list.
  static const String languagesSeparator = ', ';

  /// The button that adds the language code typed in the Translations
  /// card.
  static const String addLanguage = 'Add language';

  /// What the Club section's values are used for.
  static const String clubDescription =
      'The name the website and the emails the server sends '
      'show. Left empty, the deployment default is used.';

  /// What the Contact section's values are used for.
  static const String contactDescription =
      'How the website tells visitors to reach the club.';

  /// Shown in the Club card while it holds no value.
  static const String clubEmptyHint = 'Tap to add the club name';

  /// Shown in the Contact card while it holds no value.
  static const String contactEmptyHint = 'Tap to add contact details';

  /// Shown in the Address card while it holds no value.
  static const String addressEmptyHint = 'Tap to add the address';

  /// Toast after the Club section is saved.
  static const String clubSaved = 'Club updated.';

  /// Toast after the Contact section is saved.
  static const String contactSaved = 'Contact updated.';

  /// Toast after the Address section is saved.
  static const String addressSaved = 'Address updated.';

  /// A save that did not go through, whatever the cause.
  static const String saveFailed =
      'Could not save the club details. Please try again.';
}
