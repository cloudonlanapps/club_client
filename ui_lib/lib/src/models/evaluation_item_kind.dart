import '../constants/evaluation_strings.dart';

/// What an item of an evaluation template is: one question type, or an info
/// text. Form-local mirror of the SDK item variants; the host's adapter maps
/// between them.
enum EvaluationItemKind {
  /// A rating on stars, a range, or labelled levels.
  rating,

  /// A yes / no question.
  yesNo,

  /// One choice among several.
  singleChoice,

  /// Any number of choices.
  multipleChoice,

  /// A number.
  number,

  /// A question with a written (markdown) answer.
  qa,

  /// Markdown text shown to the reader; asks nothing.
  info;

  /// The kind's name as the designer reads it.
  String get label => switch (this) {
    EvaluationItemKind.rating => EvaluationStrings.kindRating,
    EvaluationItemKind.yesNo => EvaluationStrings.kindYesNo,
    EvaluationItemKind.singleChoice => EvaluationStrings.kindSingleChoice,
    EvaluationItemKind.multipleChoice => EvaluationStrings.kindMultipleChoice,
    EvaluationItemKind.number => EvaluationStrings.kindNumber,
    EvaluationItemKind.qa => EvaluationStrings.kindQa,
    EvaluationItemKind.info => EvaluationStrings.kindInfo,
  };

  /// Whether the item collects an answer.
  bool get isQuestion => this != EvaluationItemKind.info;

  /// Whether the item may show a comment area (a coach note). A Q & A is
  /// already written, and an info text asks nothing.
  bool get hasCommentArea =>
      this != EvaluationItemKind.qa && this != EvaluationItemKind.info;

  /// Whether the item may take evidence: every question.
  bool get allowsEvidence => isQuestion;

  /// Whether the item offers choices.
  bool get hasChoices =>
      this == EvaluationItemKind.singleChoice ||
      this == EvaluationItemKind.multipleChoice;
}
