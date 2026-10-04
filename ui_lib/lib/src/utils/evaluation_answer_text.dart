import '../constants/evaluation_strings.dart';
import '../models/evaluation_answer_value.dart';
import '../models/evaluation_item_kind.dart';
import '../models/evaluation_item_value.dart';
import '../models/evaluation_rating_style.dart';
import 'evaluation_answer_rules.dart';

/// An answer as read-only text.
abstract final class EvaluationAnswerText {
  /// [answer] to [item] as text, or `null` when it has no value. A Q & A's
  /// text is markdown.
  static String? of(EvaluationItemValue item, EvaluationAnswerValue answer) {
    if (!answer.hasValue) return null;
    final n = answer.valueNum;
    return switch (item.kind) {
      EvaluationItemKind.rating => n == null ? null : rating(item, n.toInt()),
      EvaluationItemKind.yesNo =>
        n == EvaluationAnswerRules.yesValue
            ? EvaluationAnswerRules.yesLabel(item)
            : EvaluationAnswerRules.noLabel(item),
      EvaluationItemKind.singleChoice => choiceLabel(item, answer.valueText),
      EvaluationItemKind.multipleChoice => [
        for (final c in item.choices)
          if (answer.choices.contains(c.value)) c.text,
      ].join(EvaluationStrings.choiceSeparator),
      EvaluationItemKind.number => n == null ? null : number(n),
      EvaluationItemKind.qa => answer.valueText,
      EvaluationItemKind.info => null,
    };
  }

  /// A rating [value]: its level label, else "value / highest".
  static String rating(EvaluationItemValue item, int value) {
    final scale = EvaluationAnswerRules.scaleOf(item);
    return scale.style == EvaluationRatingStyle.levels
        ? scale.labelFor(value)
        : '$value${EvaluationStrings.outOf}${scale.highest}';
  }

  /// The label of the choice worth [value], else the value itself.
  static String? choiceLabel(EvaluationItemValue item, String? value) {
    for (final c in item.choices) {
      if (c.value == value) return c.text;
    }
    return value;
  }

  /// [n] without a trailing ".0" when whole.
  static String number(num n) => n == n.truncate() ? '${n.truncate()}' : '$n';
}
