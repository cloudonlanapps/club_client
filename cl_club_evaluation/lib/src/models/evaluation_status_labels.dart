import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStatus;

import '../constants/evaluation_view_strings.dart';

/// How an evaluation's status reads, as plain text (no colour coding). A
/// `saved` evaluation reads "Finalized": drafts autosave, so finalizing is
/// the step that ends the draft.
abstract final class EvaluationStatusLabels {
  /// The coach view's groups, in order: drafts, then finalized evaluations
  /// awaiting publication, then published ones.
  static const List<EvaluationStatus> groupOrder = [
    EvaluationStatus.draft,
    EvaluationStatus.saved,
    EvaluationStatus.published,
  ];

  /// [status] as read on one evaluation.
  static String of(EvaluationStatus status) => switch (status) {
    EvaluationStatus.draft => EvaluationViewStrings.statusDraft,
    EvaluationStatus.saved => EvaluationViewStrings.statusFinalized,
    EvaluationStatus.published => EvaluationViewStrings.statusPublished,
  };

  /// The heading of a group of evaluations in [status].
  static String group(EvaluationStatus status) => switch (status) {
    EvaluationStatus.draft => EvaluationViewStrings.drafts,
    EvaluationStatus.saved => EvaluationViewStrings.finalized,
    EvaluationStatus.published => EvaluationViewStrings.published,
  };
}
