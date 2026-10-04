import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show EvaluationAnswerValue, EvaluationItemValue;

import 'evaluation_answer_adapter.dart';

/// Form → SDK for one answer of a draft (form rule 18): written whole when
/// given, cleared when emptied.
abstract final class EvaluationAnswerSubmit {
  /// Writes [answer] to [item] of [evaluation]: `putAnswer` when it gives
  /// anything, else `clearAnswer` — or nothing, returning `null`, when the
  /// item has no saved answer to clear.
  static Future<sdk.EvaluationStaffView?> save({
    required sdk.EvaluationStaffView evaluation,
    required EvaluationItemValue item,
    required EvaluationAnswerValue answer,
    required ClEvaluationsMasterNotifier notifier,
  }) async {
    final itemId = item.id!;
    final input = EvaluationAnswerAdapter.toInput(item, answer);
    if (input != null) {
      return notifier.putAnswer(evaluation.id, itemId, input);
    }
    if (evaluation.answerFor(itemId) == null) return null;
    return notifier.clearAnswer(evaluation.id, itemId);
  }

  /// Whether [save] of [answer] to [item] would clear a saved answer of
  /// [evaluation] that has evidence — which the server detaches with it.
  static bool clearsEvidence({
    required sdk.EvaluationStaffView evaluation,
    required EvaluationItemValue item,
    required EvaluationAnswerValue answer,
  }) =>
      EvaluationAnswerAdapter.toInput(item, answer) == null &&
      (evaluation.answerFor(item.id!)?.evidence.isNotEmpty ?? false);
}
