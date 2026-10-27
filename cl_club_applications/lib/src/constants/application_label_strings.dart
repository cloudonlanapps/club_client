/// What the club's application labels say (club_client#396): the Labels
/// card on Club details.
abstract final class ApplicationLabelStrings {
  /// The card's heading.
  static const String title = 'Labels';

  /// What the labels are for.
  static const String intro =
      'The fixed words every application prints: section headings, field '
      'labels, the photo box. Each is printed in the languages of the '
      'application. When a language is added in Profile options, its text '
      'is blank here until it is written, and an application printing in '
      'it cannot be finalized before. An application can still change a '
      'label for itself in its own Labels section.';

  /// The labels could not be read.
  static const String loadFailed = 'Could not load the labels.';

  /// No labels (the server gave none).
  static const String empty = 'No labels.';

  /// A label saved.
  static const String saved = 'Label updated.';

  /// A label that is gone (404 `APPLICATION_LABEL_NOT_FOUND`).
  static const String gone =
      'This label is no longer known. The list has been reloaded.';
}
