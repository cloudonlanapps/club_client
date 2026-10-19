/// Copy and fixed values of a template's export file and its Import and
/// Export actions (club_client#27).
abstract final class TemplateFileStrings {
  /// The file's `format`, naming what it holds.
  static const String format = 'club.evaluationTemplate';

  /// The one `version` of the file this app reads and writes.
  static const int version = 1;

  /// The key of the file's format.
  static const String formatKey = 'format';

  /// The key of the file's version.
  static const String versionKey = 'version';

  /// The key of the template's name.
  static const String nameKey = 'name';

  /// The key of the template's layout.
  static const String layoutKey = 'layout';

  /// The item keys the file leaves out: the server assigns both, and an
  /// imported template is new throughout.
  static const List<String> serverOwnedItemKeys = ['id', 'originItemId'];

  /// The extension of an export file.
  static const String extension = 'json';

  /// The indent the file is written with.
  static const String indent = '  ';

  /// The characters a file name cannot hold, on any platform.
  static const String fileNameForbidden = r'[\\/:*?"<>|\x00-\x1F]';

  /// What stands in for a character a file name cannot hold.
  static const String fileNameFiller = '_';

  /// The name of an export of a template whose name leaves nothing usable.
  static const String fallbackFileName = 'template';

  /// The Import button of the template library.
  static const String import = 'Import';

  /// The Export button of a template.
  static const String export = 'Export';

  /// Toast once an export is saved.
  static const String exported = 'Template exported.';

  /// Toast when an export could not be saved.
  static const String exportFailed = 'The template could not be exported.';

  /// Toast when the chosen file could not be read.
  static const String importFailed = 'The file could not be read.';

  /// Refusal of a file that is not JSON.
  static const String notJson = 'This file is not a JSON file.';

  /// Refusal of JSON that is not a template export.
  static const String notTemplateFile = 'This file is not a review template.';

  /// Refusal of a template file of an unknown version.
  static String unknownVersion(Object? version) =>
      'This template file is version $version, which this app cannot read.';

  /// Refusal of a file whose entry [position] (1-based) of the layout
  /// cannot be read.
  static String unreadableEntry(int position) =>
      'Entry $position of this template file cannot be read.';
}
