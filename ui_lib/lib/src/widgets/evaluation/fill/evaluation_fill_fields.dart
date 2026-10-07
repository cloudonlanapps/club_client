/// Field ids of `EvaluationFillBody`: one per question, holding its
/// `EvaluationAnswerValue`.
abstract final class EvaluationFillFields {
  /// Prefix of a question's field id.
  static const String prefix = 'item';

  /// The field id of the question with [itemId].
  static String idFor(int itemId) => '$prefix$itemId';
}
