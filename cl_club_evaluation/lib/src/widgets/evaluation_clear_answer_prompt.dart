import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStaffView;
import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ConfirmDialog,
        EvaluationAnswerValue,
        EvaluationFillBodyState,
        EvaluationFillFields,
        EvaluationItemValue;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_answer_adapter.dart';
import '../models/evaluation_answer_submit.dart';

/// Whether [answer] to [item] of [evaluation] may be written. Only a write
/// that clears a saved answer with evidence — which the server detaches
/// with it — needs a yes: asked in a dialog over [context]; on cancel the
/// saved answer goes back into [fill]. With no [context] (the editor has
/// closed) such a write is skipped.
Future<bool> confirmClearAnswer(
  BuildContext? context, {
  required EvaluationFillBodyState? fill,
  required EvaluationStaffView evaluation,
  required EvaluationItemValue item,
  required EvaluationAnswerValue answer,
}) async {
  if (!EvaluationAnswerSubmit.clearsEvidence(
    evaluation: evaluation,
    item: item,
    answer: answer,
  )) {
    return true;
  }
  if (context == null) return false;
  final clear = await ConfirmDialog.show(
    context,
    title: EvaluationViewStrings.clearAnswerTitle,
    message: EvaluationViewStrings.clearAnswerMessage,
    confirmLabel: EvaluationViewStrings.clear,
    destructive: true,
  );
  if (!clear) {
    final saved = evaluation.answerFor(item.id!);
    fill?.formKey.currentState?.setFieldValue<EvaluationAnswerValue>(
      EvaluationFillFields.idFor(item.id!),
      saved == null
          ? const EvaluationAnswerValue()
          : EvaluationAnswerAdapter.toValue(saved),
    );
  }
  return clear;
}
