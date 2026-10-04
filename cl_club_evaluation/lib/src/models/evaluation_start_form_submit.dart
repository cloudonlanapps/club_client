import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart' show EvaluationStartFormFields;

import 'evaluation_period_dates.dart';

/// Form → SDK for the start form (form rule 18): creates the draft.
abstract final class EvaluationStartFormSubmit {
  /// Creates a draft from [values], keyed by [EvaluationStartFormFields].
  static Future<sdk.EvaluationStaffView> create({
    required Map<String, dynamic> values,
    required ClEvaluationsMasterNotifier notifier,
  }) => notifier.createEvaluation(
    templateId: values[EvaluationStartFormFields.templateId] as int,
    createdFor: values[EvaluationStartFormFields.memberId] as String,
    eventId: values[EvaluationStartFormFields.eventId] as int?,
    periodStartUtc: EvaluationPeriodDates.toUtc(
      values[EvaluationStartFormFields.periodStartId] as DateTime?,
    ),
    periodEndUtc: EvaluationPeriodDates.toUtc(
      values[EvaluationStartFormFields.periodEndId] as DateTime?,
    ),
  );
}
