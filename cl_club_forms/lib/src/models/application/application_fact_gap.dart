import 'package:flutter/foundation.dart';

/// A `{name}` gap of an application's printed text that names no fact of
/// its template (club_client#389): where the text is, the language of the
/// text it is in, and the gap's name. Save is refused while there is one.
@immutable
class ApplicationFactGap {
  const ApplicationFactGap({
    required this.place,
    required this.language,
    required this.name,
  });

  /// The text's place, as the server names it: `title`, `header[1]`,
  /// `header[1][0]` (a line of a header item), `selections[2]`,
  /// `terms[0].body`, `terms_notes[0].attribution`, …; 0-based.
  final String place;

  /// The language code of the text the gap is in.
  final String language;

  /// The gap's name, without its braces.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationFactGap &&
          other.place == place &&
          other.language == language &&
          other.name == name;

  @override
  int get hashCode => Object.hash(place, language, name);

  @override
  String toString() => '$place ($language): $name';
}
