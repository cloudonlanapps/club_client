import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier, schemaFieldErrors;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart' show EvaluationStartFormFields;

import 'evaluation_period_dates.dart';

/// Form → SDK for the start form (form rule 18): creates the draft.
abstract final class EvaluationStartFormSubmit {
  /// The server's name for the template.
  static const String serverTemplateId = 'templateId';

  /// The server's name for the member the evaluation is for.
  static const String serverCreatedFor = 'createdFor';

  /// The server's name for the event.
  static const String serverEventId = 'eventId';

  /// The server's name for the start of the period.
  static const String serverPeriodStart = 'periodStartUtc';

  /// The server's name for the end of the period.
  static const String serverPeriodEnd = 'periodEndUtc';

  /// The fields of a new evaluation, as the server names them in a schema
  /// rejection (club_client#114), each with the id of the form field that
  /// holds it.
  static const Map<String, String> schemaFieldIds = {
    serverTemplateId: EvaluationStartFormFields.templateId,
    serverCreatedFor: EvaluationStartFormFields.memberId,
    serverEventId: EvaluationStartFormFields.eventId,
    serverPeriodStart: EvaluationStartFormFields.periodStartId,
    serverPeriodEnd: EvaluationStartFormFields.periodEndId,
  };

  /// What the start form shows on its fields for a draft the server
  /// refused with [error] at its schema. Empty when [error] names no field;
  /// the host then shows the failure inline.
  static Map<String, String> fieldErrorsFor(Object error) =>
      schemaFieldErrors(error, schemaFieldIds);

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
