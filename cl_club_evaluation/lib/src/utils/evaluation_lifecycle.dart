import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier;

import '../models/evaluation_step.dart';

/// Runs a lifecycle step through the evaluations master.
abstract final class EvaluationLifecycle {
  /// Runs [step] on evaluation [id]; a transfer goes to coach [owner].
  static Future<void> perform(
    EvaluationStep step, {
    required int id,
    required ClEvaluationsMasterNotifier notifier,
    String? owner,
  }) => switch (step) {
    EvaluationStep.save => notifier.saveEvaluation(id),
    EvaluationStep.publish => notifier.publishEvaluation(id),
    EvaluationStep.unpublish => notifier.unpublishEvaluation(id),
    EvaluationStep.revert => notifier.revertEvaluation(id),
    EvaluationStep.transfer => notifier.transferEvaluation(id, owner: owner!),
    EvaluationStep.delete => notifier.deleteEvaluation(id),
  };
}
