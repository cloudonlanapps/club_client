/// Copy of the template library's deleted view and its **Restore**
/// (club_client#277).
abstract final class TemplateRestoreStrings {
  /// The switch between the live templates and the deleted ones.
  static const String showDeleted = 'Show deleted templates';

  /// The library's heading while it shows the deleted templates.
  static const String deletedTemplates = 'Deleted templates';

  /// A library with no deleted template.
  static const String noDeletedTemplates = 'No deleted templates.';

  /// Brings a deleted template back to the library.
  static const String restore = 'Restore';

  /// The template was restored under its own name.
  static const String templateRestored = 'Template restored.';

  /// A restore of a template that is not deleted: another staff member
  /// restored it first (`NOTHING_TO_RESTORE`).
  static const String nothingToRestore = 'This template was already restored.';

  /// The template was restored under [name], because a live template
  /// holds the name it was deleted with.
  static String restoredAs(String name) =>
      'Template restored as "$name": its name is taken by another template.';
}
