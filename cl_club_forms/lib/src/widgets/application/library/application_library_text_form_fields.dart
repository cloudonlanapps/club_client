/// Field ids of `ApplicationLibraryTextForm` (club_client#389), and the
/// keys of its initial values and of the map it returns.
abstract final class ApplicationLibraryTextFormFields {
  /// Where the text is used: an `ApplicationClauseKind`.
  static const String kindId = 'kind';

  /// The short name the editor's lists show, 1–[nameMaxLength] characters.
  static const String nameId = 'name';

  /// A term's heading, by language code; a term's alone.
  static const String headingId = 'heading';

  /// The text, by language code, `{fact}` gaps as written.
  static const String textId = 'text';

  /// The longest name the server takes.
  static const int nameMaxLength = 100;
}
