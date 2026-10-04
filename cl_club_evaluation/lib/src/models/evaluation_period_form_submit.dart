import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart' show EvaluationStartFormFields;

import 'evaluation_period_dates.dart';

/// Form → SDK for the Review Period section editor (form rule 18): sends
/// the event and the period through `updateEvaluation`, each only when it
/// changed.
abstract final class EvaluationPeriodFormSubmit {
  /// Writes draft [evaluation]'s Review Period from [values] — the period
  /// form's `validate()` result: its event (`null` makes it general) and its
  /// period (both dates empty clears it). A field equal to [evaluation]'s is
  /// left out; with nothing changed no call is made and [evaluation] is
  /// returned.
  static Future<sdk.EvaluationStaffView> updateReviewPeriod({
    required sdk.EvaluationStaffView evaluation,
    required Map<String, dynamic> values,
    required ClEvaluationsMasterNotifier notifier,
  }) async {
    final eventId = values[EvaluationStartFormFields.eventId] as int?;
    final start = EvaluationPeriodDates.toUtc(
      values[EvaluationStartFormFields.periodStartId] as DateTime?,
    );
    final end = EvaluationPeriodDates.toUtc(
      values[EvaluationStartFormFields.periodEndId] as DateTime?,
    );
    final eventChanged = eventId != evaluation.eventId;
    final periodChanged =
        start != evaluation.periodStartUtc || end != evaluation.periodEndUtc;
    if (!eventChanged && !periodChanged) return evaluation;
    return notifier.updateEvaluation(
      evaluation.id,
      eventId: eventChanged ? () => eventId : null,
      periodStartUtc: periodChanged ? () => start : null,
      periodEndUtc: periodChanged ? () => end : null,
    );
  }
}
