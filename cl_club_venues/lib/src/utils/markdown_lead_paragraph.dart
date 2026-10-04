/// Matches a blank line (optionally holding whitespace) between two blocks.
final RegExp markdownBlockSeparator = RegExp(r'\n[ \t]*\n');

/// Matches an ATX heading line (`# Title`, `## Title`, …).
final RegExp markdownHeadingLine = RegExp(r'^\s{0,3}#{1,6}(\s|$)');

/// The first paragraph of a markdown document, as markdown.
///
/// Descriptions are long-form (headings, several paragraphs), so a preview
/// built from the whole document would put a mid-document heading on a card.
/// This returns the first block that still has text once its heading lines
/// are dropped, or an empty string when there is none.
String markdownLeadParagraph(String markdown) {
  for (final block in markdown.trim().split(markdownBlockSeparator)) {
    final text = block
        .split('\n')
        .where((line) => !markdownHeadingLine.hasMatch(line))
        .join('\n')
        .trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
