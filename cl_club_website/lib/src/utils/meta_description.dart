/// The longest description a search result shows in full.
const metaDescriptionMaxLength = 160;

/// [text] as a page description: one plain line, without Markdown emphasis,
/// cut at a word when longer than [metaDescriptionMaxLength]. Null when
/// there is nothing to say.
String? metaDescriptionFrom(String? text) {
  if (text == null) return null;
  final line = text.replaceAll('**', '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (line.isEmpty) return null;
  if (line.length <= metaDescriptionMaxLength) return line;
  final cut = line.substring(0, metaDescriptionMaxLength);
  final lastSpace = cut.lastIndexOf(' ');
  return '${cut.substring(0, lastSpace > 0 ? lastSpace : cut.length - 1)}…';
}
