/// Field ids of `EvaluationStartForm` and `EvaluationPeriodForm`, and so the
/// keys of the maps their `validate()` returns: [templateId] `int`,
/// [memberId] `String` (a username), [eventId] `int?` (`null` = general),
/// [periodStartId] and [periodEndId] `DateTime?` (local dates; both or
/// neither).
abstract final class EvaluationStartFormFields {
  /// The template the evaluation is written against.
  static const String templateId = 'templateId';

  /// The member the evaluation is about.
  static const String memberId = 'member';

  /// The event it is about; `null` for a general evaluation.
  static const String eventId = 'eventId';

  /// The first day of the review period.
  static const String periodStartId = 'periodStart';

  /// The last day of the review period.
  static const String periodEndId = 'periodEnd';
}
