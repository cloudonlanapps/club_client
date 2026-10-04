import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show EvaluationAnswerValue, EvaluationItemKind, EvaluationItemValue;

/// The adapter between the SDK's answers and the ui_lib fill form's
/// `EvaluationAnswerValue` (form rules 7, 18).
abstract final class EvaluationAnswerAdapter {
  /// [answer] as the form-local value.
  static EvaluationAnswerValue toValue(sdk.EvaluationAnswer answer) =>
      EvaluationAnswerValue(
        valueNum: answer.valueNum,
        valueText: answer.valueText,
        choices: answer.choices,
        coachNote: answer.coachNote,
      );

  /// [answers] as form-local values by item id.
  static Map<int, EvaluationAnswerValue> toValues(
    List<sdk.EvaluationAnswer> answers,
  ) => {for (final a in answers) a.itemId: toValue(a)};

  /// [answer] to [item] as the write the SDK sends — only the field the
  /// item's kind uses, a yes / no as 1 / 0, and the coach note — or `null`
  /// when nothing is given, which clears the answer.
  static sdk.EvaluationAnswerInput? toInput(
    EvaluationItemValue item,
    EvaluationAnswerValue answer,
  ) {
    if (answer.isEmpty || !item.kind.isQuestion) return null;
    final note = answer.hasCoachNote ? answer.coachNote : null;
    final text = answer.valueText;
    return switch (item.kind) {
      EvaluationItemKind.yesNo when answer.valueNum != null =>
        sdk.EvaluationAnswerInput.yesNo(
          yes: answer.valueNum == sdk.EvaluationAnswerInput.yesValue,
          coachNote: note,
        ),
      EvaluationItemKind.rating ||
      EvaluationItemKind.yesNo ||
      EvaluationItemKind.number => sdk.EvaluationAnswerInput(
        valueNum: answer.valueNum,
        coachNote: note,
      ),
      EvaluationItemKind.singleChoice ||
      EvaluationItemKind.qa => sdk.EvaluationAnswerInput(
        valueText: text == null || text.trim().isEmpty ? null : text,
        coachNote: note,
      ),
      EvaluationItemKind.multipleChoice => sdk.EvaluationAnswerInput(
        choices: answer.choices.isEmpty ? null : answer.choices,
        coachNote: note,
      ),
      EvaluationItemKind.info => null,
    };
  }
}
