import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import '../constants/evaluation_view_strings.dart';

/// What a failed evaluation write says to the person (Section-wise Editors
/// rule 5): a fixed message per refusal, never the raw exception. A copy
/// that strays from its origin shows the server's own message, which names
/// what differs.
abstract final class EvaluationErrorMessage {
  /// The message for [error], or [fallback] when nothing more specific
  /// applies.
  static String of(
    Object error, {
    String fallback = EvaluationViewStrings.saveFailed,
  }) => refusalOf(error) ?? fallback;

  /// The message for a refusal by the server that says what is wrong with
  /// what was sent, to show in the form. Null for a failure that is not
  /// about it — the server not reached, an unexpected error — which the
  /// host reports in a toast.
  static String? refusalOf(Object error) {
    if (error is! ServerException) return null;
    return switch (error.code) {
      SdkErrorCode.templateInUse => EvaluationViewStrings.templateInUse,
      SdkErrorCode.originMismatch => error.message,
      SdkErrorCode.notEligible => EvaluationViewStrings.notEligible,
      SdkErrorCode.invalidState => EvaluationViewStrings.invalidState,
      SdkErrorCode.incomplete => EvaluationViewStrings.incomplete,
      SdkErrorCode.invalidEvidence => EvaluationViewStrings.invalidEvidence,
      SdkErrorCode.invalidAnswer => EvaluationViewStrings.invalidAnswer,
      SdkErrorCode.invalidLayout => EvaluationViewStrings.invalidLayout,
      SdkErrorCode.itemTypeFixed => EvaluationViewStrings.itemTypeFixed,
      SdkErrorCode.templateNameTaken => EvaluationViewStrings.templateNameTaken,
      SdkErrorCode.duplicateEvaluation =>
        EvaluationViewStrings.duplicateEvaluation,
      SdkErrorCode.periodInFuture => EvaluationViewStrings.periodInFuture,
      SdkErrorCode.eventNotFound => EvaluationViewStrings.eventNotFound,
      _ => null,
    };
  }

  /// Whether [error] is the server's refusal to change a used template.
  static bool isTemplateInUse(Object error) =>
      error is ServerException && error.code == SdkErrorCode.templateInUse;

  /// Whether [error] is the server's refusal of a template name already
  /// taken.
  static bool isTemplateNameTaken(Object error) =>
      error is ServerException && error.code == SdkErrorCode.templateNameTaken;
}
