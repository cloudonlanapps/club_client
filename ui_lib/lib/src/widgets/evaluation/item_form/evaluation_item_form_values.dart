import '../../../models/evaluation_choice.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../models/evaluation_rating_scale.dart';
import '../../../models/evaluation_rating_style.dart';
import '../../../utils/evaluation_answer_rules.dart';
import '../../../utils/evaluation_choice_values.dart';
import 'evaluation_item_form_fields.dart';

/// Converts between [EvaluationItemValue] and the flat values of
/// `EvaluationItemForm`, keyed by [EvaluationItemFormFields].
abstract final class EvaluationItemFormValues {
  /// [item] as the form's initial values.
  static Map<String, dynamic> fromItem(EvaluationItemValue item) {
    final scale = EvaluationAnswerRules.scaleOf(item);
    return {
      EvaluationItemFormFields.textId: item.text,
      EvaluationItemFormFields.isRequiredId: item.isRequired,
      EvaluationItemFormFields.isPrivateId: item.isPrivate,
      EvaluationItemFormFields.allowEvidenceId: item.allowEvidence,
      EvaluationItemFormFields.showCommentAreaId: item.showCommentArea,
      EvaluationItemFormFields.requireCommentForId: List<Object>.of(
        item.requireCommentFor,
      ),
      EvaluationItemFormFields.ratingStyleId: scale.style,
      EvaluationItemFormFields.rateMinId: '${scale.min}',
      EvaluationItemFormFields.rateMaxId: '${scale.max}',
      EvaluationItemFormFields.levelsId: List<String>.of(scale.levels),
      EvaluationItemFormFields.labelTrueId: item.labelTrue ?? '',
      EvaluationItemFormFields.labelFalseId: item.labelFalse ?? '',
      EvaluationItemFormFields.choicesId: [
        for (final c in item.choices) c.text,
      ],
    };
  }

  /// The item of [kind] (and [id]) that [values] describe — either the
  /// form's raw values or what its `validate()` returned. Unparsable bounds
  /// fall back to the default scale.
  static EvaluationItemValue toItem(
    Map<String, dynamic> values, {
    required EvaluationItemKind kind,
    int? id,
  }) {
    final showCommentArea =
        kind.hasCommentArea &&
        values[EvaluationItemFormFields.showCommentAreaId] == true;
    return EvaluationItemValue(
      id: id,
      kind: kind,
      text: (values[EvaluationItemFormFields.textId] as String? ?? '').trim(),
      isRequired:
          kind.isQuestion &&
          values[EvaluationItemFormFields.isRequiredId] == true,
      isPrivate: values[EvaluationItemFormFields.isPrivateId] == true,
      allowEvidence:
          kind.allowsEvidence &&
          values[EvaluationItemFormFields.allowEvidenceId] == true,
      showCommentArea: showCommentArea,
      requireCommentFor: showCommentArea
          ? List<Object>.from(
              values[EvaluationItemFormFields.requireCommentForId] as List? ??
                  [],
            )
          : const [],
      scale: kind == EvaluationItemKind.rating ? scaleOf(values) : null,
      labelTrue: kind == EvaluationItemKind.yesNo
          ? EvaluationAnswerRules.nonEmpty(
              values[EvaluationItemFormFields.labelTrueId] as String?,
            )?.trim()
          : null,
      labelFalse: kind == EvaluationItemKind.yesNo
          ? EvaluationAnswerRules.nonEmpty(
              values[EvaluationItemFormFields.labelFalseId] as String?,
            )?.trim()
          : null,
      choices: kind.hasChoices ? choicesOf(values) : const [],
    );
  }

  /// The rating scale [values] describe.
  static EvaluationRatingScale scaleOf(Map<String, dynamic> values) {
    final style =
        values[EvaluationItemFormFields.ratingStyleId]
            as EvaluationRatingStyle? ??
        EvaluationRatingStyle.stars;
    if (style == EvaluationRatingStyle.levels) {
      return EvaluationRatingScale.levels([
        for (final l
            in values[EvaluationItemFormFields.levelsId] as List? ?? const [])
          '$l'.trim(),
      ]);
    }
    return EvaluationRatingScale(
      style: style,
      min:
          intOf(values[EvaluationItemFormFields.rateMinId]) ??
          EvaluationRatingScale.defaultMin,
      max:
          intOf(values[EvaluationItemFormFields.rateMaxId]) ??
          EvaluationRatingScale.defaultMax,
    );
  }

  /// The choices [values] describe: validated choices as they are, labels
  /// with values derived from them.
  static List<EvaluationChoice> choicesOf(Map<String, dynamic> values) {
    final raw = values[EvaluationItemFormFields.choicesId] as List? ?? const [];
    if (raw.every((c) => c is EvaluationChoice)) {
      return List<EvaluationChoice>.from(raw);
    }
    return EvaluationChoiceValues.fromLabels([for (final l in raw) '$l']);
  }

  /// [value] as a whole number: an `int`, or text that parses as one.
  static int? intOf(Object? value) =>
      value is int ? value : int.tryParse('${value ?? ''}'.trim());
}
