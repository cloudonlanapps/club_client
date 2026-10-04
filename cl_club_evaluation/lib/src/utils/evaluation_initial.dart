import 'package:flutter/widgets.dart' show StringCharacters;

/// The first letter of [text], upper-cased, for a row's leading image;
/// empty for empty text.
String evaluationInitial(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? '' : trimmed.characters.first.toUpperCase();
}
