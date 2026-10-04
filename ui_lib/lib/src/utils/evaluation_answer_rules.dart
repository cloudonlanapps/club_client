import '../constants/evaluation_strings.dart';
import '../models/evaluation_answer_value.dart';
import '../models/evaluation_item_kind.dart';
import '../models/evaluation_item_value.dart';
import '../models/evaluation_rating_scale.dart';

/// The rules an answer follows, shared by the fill form, the read body and
/// the item form's coach-note rule.
abstract final class EvaluationAnswerRules {
  /// The value a yes / no answer stores for yes.
  static const int yesValue = 1;

  /// The value a yes / no answer stores for no.
  static const int noValue = 0;

  /// The answers [item] can take with their labels, in order — the options
  /// a coach note can be required for — or `null` for free input (number,
  /// Q & A, info text).
  static List<(Object, String)>? answerOptions(EvaluationItemValue item) =>
      switch (item.kind) {
        EvaluationItemKind.rating => [
          for (final v in scaleOf(item).values) (v, scaleOf(item).labelFor(v)),
        ],
        EvaluationItemKind.yesNo => [
          (true, yesLabel(item)),
          (false, noLabel(item)),
        ],
        EvaluationItemKind.singleChoice ||
        EvaluationItemKind.multipleChoice => [
          for (final c in item.choices) (c.value, c.text),
        ],
        EvaluationItemKind.number ||
        EvaluationItemKind.qa ||
        EvaluationItemKind.info => null,
      };

  /// [item]'s rating scale; five stars when it has none.
  static EvaluationRatingScale scaleOf(EvaluationItemValue item) =>
      item.scale ?? const EvaluationRatingScale.stars();

  /// The label of yes for [item].
  static String yesLabel(EvaluationItemValue item) =>
      nonEmpty(item.labelTrue) ?? EvaluationStrings.yes;

  /// The label of no for [item].
  static String noLabel(EvaluationItemValue item) =>
      nonEmpty(item.labelFalse) ?? EvaluationStrings.no;

  /// [text], or `null` when it is empty or blank.
  static String? nonEmpty(String? text) =>
      text == null || text.trim().isEmpty ? null : text;

  /// The values of [answer] that a coach-note rule compares against: an
  /// `int` rating, a `bool` yes / no, the chosen choice value(s).
  static List<Object> ruleKeys(
    EvaluationItemValue item,
    EvaluationAnswerValue answer,
  ) => switch (item.kind) {
    EvaluationItemKind.rating => [
      if (answer.valueNum != null) answer.valueNum!.toInt(),
    ],
    EvaluationItemKind.yesNo => [
      if (answer.valueNum != null) answer.valueNum == yesValue,
    ],
    EvaluationItemKind.singleChoice => [
      if (answer.valueText != null) answer.valueText!,
    ],
    EvaluationItemKind.multipleChoice => answer.choices,
    EvaluationItemKind.number ||
    EvaluationItemKind.qa ||
    EvaluationItemKind.info => const [],
  };

  /// Whether [answer] makes [item]'s coach note required.
  static bool noteRequired(
    EvaluationItemValue item,
    EvaluationAnswerValue answer,
  ) =>
      item.showCommentArea &&
      item.requireCommentFor.isNotEmpty &&
      ruleKeys(item, answer).any(item.requireCommentFor.contains);

  /// Why [answer] cannot be saved for [item], or `null` when it can: a
  /// required question needs a value, and an answer in the item's
  /// `requireCommentFor` needs a coach note. Drafts skip this.
  static String? validate(
    EvaluationItemValue item,
    EvaluationAnswerValue answer,
  ) {
    if (!item.kind.isQuestion) return null;
    if (item.isRequired && !answer.hasValue) {
      return EvaluationStrings.answerRequired;
    }
    if (noteRequired(item, answer) && !answer.hasCoachNote) {
      return EvaluationStrings.noteRequired;
    }
    return null;
  }
}
