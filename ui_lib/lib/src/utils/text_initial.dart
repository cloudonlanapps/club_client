import 'package:flutter/widgets.dart' show StringCharacters;

/// The first user-perceived character of [text], upper-cased, for a
/// row's initials: a whole emoji or grapheme cluster, never half of one.
/// Empty for blank text.
String textInitial(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase();
}
