/// A template file refused on import, with [message] saying why, in words
/// for people (club_client#27).
class TemplateFileException implements Exception {
  /// A refusal saying [message].
  const TemplateFileException(this.message);

  /// Why the file was refused.
  final String message;

  @override
  String toString() => 'TemplateFileException: $message';
}
