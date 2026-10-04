/// A template or an event the start form offers: its `id` and the `label`
/// the coach reads. Form-local and SDK-free.
typedef EvaluationStartChoice = ({int id, String label});

/// A member the start form offers: their `username` and the `label` the
/// coach reads. Form-local and SDK-free.
typedef EvaluationStartMember = ({String username, String label});

/// The start form's event field: an event by `id`, or general when `id` is
/// `null`.
typedef EvaluationStartEvent = ({int? id, String label});
