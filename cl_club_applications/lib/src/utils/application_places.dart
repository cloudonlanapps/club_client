import '../constants/application_view_strings.dart';

/// Names the place of a text in an application template as the editor shows
/// it, from the path the client's check (`ApplicationCompleteness`) or the
/// server's refusal gives: `form_footer` or `formFooter` → "Footer line",
/// `terms[1].body` → "Term 2 text", `termsNotes[0].text` → "Note 1",
/// `header[0][1]` → "Item 1, line 2".
abstract final class ApplicationPlaces {
  /// A list item's path: its list, its index and what follows.
  static final RegExp itemPattern = RegExp(r'^(\w+)\[(\d+)\](?:\.(\w+))?$');

  /// A line of a header item held as lines: `header[i][j]`
  /// (club_server#127).
  static final RegExp headerLinePattern = RegExp(r'^header\[(\d+)\]\[(\d+)\]$');

  /// The server's path of a label override.
  static const String labelPrefix = 'labelOverrides.';

  /// [place] as shown; itself when it is none the editor knows.
  static String label(String place) {
    final named = ApplicationViewStrings.placeNames[place];
    if (named != null) return named;
    if (place.startsWith(labelPrefix)) {
      return 'Label ${place.substring(labelPrefix.length)}';
    }
    final line = headerLinePattern.firstMatch(place);
    if (line != null) {
      return ApplicationViewStrings.headerLine(
        int.parse(line.group(1)!) + 1,
        int.parse(line.group(2)!) + 1,
      );
    }
    final match = itemPattern.firstMatch(place);
    if (match == null) return place;
    final n = int.parse(match.group(2)!) + 1;
    return switch ((match.group(1), match.group(3))) {
      ('terms', 'heading') => 'Term $n heading',
      ('terms', _) => 'Term $n text',
      ('terms_notes' || 'termsNotes', 'attribution') =>
        ApplicationViewStrings.noteAttribution(n),
      ('terms_notes' || 'termsNotes', _) => ApplicationViewStrings.note(n),
      ('selections', _) => ApplicationViewStrings.selection(n),
      ('header', _) => ApplicationViewStrings.headerItem(n),
      _ => place,
    };
  }

  /// [places], each as shown, joined.
  static String join(Iterable<String> places) =>
      places.map(label).toSet().join(', ');
}
