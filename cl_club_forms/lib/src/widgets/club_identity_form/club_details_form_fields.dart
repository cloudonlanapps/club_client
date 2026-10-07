/// Field-id constants and labels of the `ShadForm` inside `ClubDetailsForm`.
class ClubDetailsFormFields {
  ClubDetailsFormFields._();

  /// The club's full name.
  static const String nameId = 'name';

  /// The club's short name.
  static const String shortNameId = 'shortName';

  /// The club's tagline; translatable.
  static const String taglineId = 'tagline';

  /// Where messages from the website contact form are sent.
  static const String inquiryEmailId = 'inquiryEmail';

  /// Label of [nameId].
  static const String nameLabel = 'Name';

  /// Label of [shortNameId].
  static const String shortNameLabel = 'Short name';

  /// Label of [taglineId].
  static const String taglineLabel = 'Tagline';

  /// Label of [inquiryEmailId].
  static const String inquiryEmailLabel = 'Inquiry email';

  /// Help under [inquiryEmailId].
  static const String inquiryEmailHelp =
      'Where messages from the website contact form are sent. '
      'Not shown publicly.';

  /// Every field's label, in the order the form shows them.
  static const Map<String, String> labels = {
    nameId: nameLabel,
    shortNameId: shortNameLabel,
    taglineId: taglineLabel,
    inquiryEmailId: inquiryEmailLabel,
  };

  /// The plain text fields; each value is a `String`.
  static const List<String> textIds = [nameId, shortNameId, inquiryEmailId];

  /// The translatable fields; each value is a `FormTranslatedText`.
  static const List<String> translatedIds = [taglineId];
}
