import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStaffView;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart'
    show EvaluationAnswerValue, EvaluationFillBodyState, EvaluationItemValue;

import '../models/evaluation_answer_submit.dart';
import '../widgets/evaluation_clear_answer_prompt.dart';

/// Writes the owner's answers to one evaluation, for `EvaluationAutosave`:
/// each to the evaluation as last read or written.
class EvaluationAnswerWriter {
  /// Writes through [notifier], starting from [latest].
  EvaluationAnswerWriter({
    required this.notifier,
    required this.latest,
    required this.context,
    required this.fill,
  });

  /// The evaluations master, kept for writes that outlive the view.
  final ClEvaluationsMasterNotifier notifier;

  /// The evaluation as last read or written, for the next answer write.
  EvaluationStaffView latest;

  /// The template's items by id.
  Map<int, EvaluationItemValue> items = const {};

  /// Where to ask before clearing; `null` once the editor has closed.
  final BuildContext? Function() context;

  /// The fill form, to put a saved answer back.
  final EvaluationFillBodyState? Function() fill;

  /// Whether writing [answer] to [itemId] would clear an answer with
  /// evidence, which asks first.
  bool clearsEvidence(int itemId, EvaluationAnswerValue answer) {
    final item = items[itemId];
    return item != null &&
        EvaluationAnswerSubmit.clearsEvidence(
          evaluation: latest,
          item: item,
          answer: answer,
        );
  }

  /// Writes [answer] to item [itemId] of the evaluation as it stands now;
  /// clearing an answer that has evidence is confirmed first.
  Future<void> write(int itemId, EvaluationAnswerValue answer) async {
    final item = items[itemId];
    if (item == null) return;
    final go = await confirmClearAnswer(
      context(),
      fill: fill(),
      evaluation: latest,
      item: item,
      answer: answer,
    );
    if (!go) return;
    final written = await EvaluationAnswerSubmit.save(
      evaluation: latest,
      item: item,
      answer: answer,
      notifier: notifier,
    );
    if (written != null) latest = written;
  }
}
