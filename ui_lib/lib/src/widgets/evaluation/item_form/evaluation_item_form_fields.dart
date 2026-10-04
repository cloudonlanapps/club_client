/// Field ids of `EvaluationItemForm`, and so the keys of its initial values
/// and of the map its `validate()` returns.
///
/// Form values: [textId] `String`; [isRequiredId], [isPrivateId],
/// [allowEvidenceId], [showCommentAreaId] `bool`; [requireCommentForId]
/// `List<Object>` (answer values); [ratingStyleId] `EvaluationRatingStyle`;
/// [rateMinId], [rateMaxId] `String` while editing, `int` once validated;
/// [levelsId] `List<String>` (labels, lowest first); [labelTrueId],
/// [labelFalseId] `String` while editing, `String?` once validated;
/// [choicesId] `List<String>` (labels) while editing,
/// `List<EvaluationChoice>` (values derived from the labels) once validated.
abstract final class EvaluationItemFormFields {
  /// The question, or an info text's markdown.
  static const String textId = 'text';

  /// Whether saving needs an answer.
  static const String isRequiredId = 'isRequired';

  /// Whether the item is hidden from the member.
  static const String isPrivateId = 'isPrivate';

  /// Whether the answer may carry evidence.
  static const String allowEvidenceId = 'allowEvidence';

  /// Whether a coach note shows under the answer.
  static const String showCommentAreaId = 'showCommentArea';

  /// The answers that require the coach note.
  static const String requireCommentForId = 'requireCommentFor';

  /// A rating's style.
  static const String ratingStyleId = 'ratingStyle';

  /// A stars or range rating's lowest value.
  static const String rateMinId = 'rateMin';

  /// A stars or range rating's highest value.
  static const String rateMaxId = 'rateMax';

  /// A labelled-levels rating's level labels.
  static const String levelsId = 'levels';

  /// A yes / no question's label for yes.
  static const String labelTrueId = 'labelTrue';

  /// A yes / no question's label for no.
  static const String labelFalseId = 'labelFalse';

  /// A choice question's choices.
  static const String choicesId = 'choices';
}
