import 'package:ui_lib/ui_lib.dart'
    show EvaluationStartChoice, EvaluationStartMember;

/// What the start form offers a coach: the live `templates`, the active
/// `members`, the `events` the coach coaches, and `eventsByMember` — of
/// those, the ones each member is enrolled in — and, where the caller fixed
/// one, that template, member or event, named.
typedef StartReviewOptions = ({
  List<EvaluationStartChoice> templates,
  List<EvaluationStartMember> members,
  List<EvaluationStartChoice> events,
  Map<String, List<EvaluationStartChoice>> eventsByMember,
  EvaluationStartChoice? fixedTemplate,
  EvaluationStartMember? fixedMember,
  EvaluationStartChoice? fixedEvent,
});
