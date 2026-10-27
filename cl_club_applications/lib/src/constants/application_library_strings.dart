import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationClauseKind;

/// What the club's library of application texts says (club_client#389,
/// #396): the Library card on Club details and its dialog.
abstract final class ApplicationLibraryStrings {
  /// The section's heading.
  static const String title = 'Library';

  /// What the library is for.
  static const String intro =
      "The club's texts, offered under each section of every application. "
      'The texts the server starts with are here too: edit or delete any '
      'of them like a text you added. A {name} in a text prints the fact '
      'of that name of the application it is pasted into.';

  /// The add button and the dialog's title.
  static const String add = 'Add text';

  /// The library is empty.
  static const String empty =
      'No texts yet. Add one to offer it in every '
      'application.';

  /// The library could not be read.
  static const String loadFailed = 'Could not load the library.';

  /// The read mode's row of a text's kind.
  static const String usedFor = 'Used for';

  /// Where a text of [kind] is used, as the library's form names it.
  static String kindName(ApplicationClauseKind kind) => switch (kind) {
    ApplicationClauseKind.header => 'Header item',
    ApplicationClauseKind.selection => 'Selection',
    ApplicationClauseKind.declaration => 'Declaration',
    ApplicationClauseKind.rule => 'Term',
    ApplicationClauseKind.note => 'Note',
  };

  /// The read mode's row of a term's heading in [language].
  static String heading(String language) => 'Heading ($language)';

  /// The read mode's row of the text in [language].
  static String text(String language) => 'Text ($language)';

  /// The delete action.
  static const String delete = 'Delete';

  /// Delete's confirmation title.
  static const String deleteTitle = 'Delete this text?';

  /// Delete's confirmation message.
  static const String deleteMessage =
      'It is no longer offered. Applications it was pasted into keep their '
      'text.';

  /// A text added.
  static const String added = 'Text added to the library.';

  /// A text saved.
  static const String saved = 'Library text updated.';

  /// A text deleted.
  static const String deleted = 'Text deleted from the library.';

  /// A text that is gone (404 `APPLICATION_LIBRARY_TEXT_NOT_FOUND`).
  static const String gone =
      'This text is no longer in the library. The list has been reloaded.';
}
