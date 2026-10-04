import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStatus;

import '../constants/evaluation_view_strings.dart';

/// A lifecycle action the effective owner takes on an evaluation (R14–R24):
/// which ones a status offers, and what each is called.
enum EvaluationStep {
  /// draft → saved, read as **Finalize** (drafts autosave).
  save,

  /// saved → published.
  publish,

  /// published → saved.
  unpublish,

  /// saved → draft.
  revert,

  /// Hands it to another coach; offered once finalized (the server also
  /// allows it on a draft).
  transfer,

  /// Deletes a draft.
  delete;

  /// The action's label.
  String get label => switch (this) {
    EvaluationStep.save => EvaluationViewStrings.finalize,
    EvaluationStep.publish => EvaluationViewStrings.publish,
    EvaluationStep.unpublish => EvaluationViewStrings.unpublish,
    EvaluationStep.revert => EvaluationViewStrings.revert,
    EvaluationStep.transfer => EvaluationViewStrings.transfer,
    EvaluationStep.delete => EvaluationViewStrings.delete,
  };

  /// What the toast says once the action is done.
  String get doneMessage => switch (this) {
    EvaluationStep.save => EvaluationViewStrings.evaluationFinalized,
    EvaluationStep.publish => EvaluationViewStrings.evaluationPublished,
    EvaluationStep.unpublish => EvaluationViewStrings.evaluationUnpublished,
    EvaluationStep.revert => EvaluationViewStrings.evaluationReverted,
    EvaluationStep.transfer => EvaluationViewStrings.evaluationTransferred,
    EvaluationStep.delete => EvaluationViewStrings.evaluationDeleted,
  };

  /// Whether the action removes or loses something.
  bool get isDestructive => this == EvaluationStep.delete;

  /// The actions [status] offers, the primary one first: a draft Finalize
  /// and Delete; a finalized one Publish, Revert to draft and Transfer; a
  /// published one Unpublish only.
  static List<EvaluationStep> forStatus(EvaluationStatus status) =>
      switch (status) {
        EvaluationStatus.draft => const [
          EvaluationStep.save,
          EvaluationStep.delete,
        ],
        EvaluationStatus.saved => const [
          EvaluationStep.publish,
          EvaluationStep.revert,
          EvaluationStep.transfer,
        ],
        EvaluationStatus.published => const [EvaluationStep.unpublish],
      };
}
