import '../constants/evaluation_strings.dart';
import '../models/evaluation_item_value.dart';

/// How an item reads in the layout outline.
abstract final class EvaluationOutlineText {
  /// Markdown marks dropped from an outline title.
  static final RegExp markdownMarks = RegExp(r'[#*_>`~\[\]]');

  /// [item]'s first line without markdown marks.
  static String titleOf(EvaluationItemValue item) {
    final line = item.text.trim().split('\n').first;
    return line.replaceAll(markdownMarks, '').trim();
  }

  /// [item]'s kind, with Required and Private when set.
  static String captionOf(EvaluationItemValue item) => [
    item.kind.label,
    if (item.isRequired) EvaluationStrings.required,
    if (item.isPrivate) EvaluationStrings.private,
  ].join(EvaluationStrings.captionSeparator);
}
