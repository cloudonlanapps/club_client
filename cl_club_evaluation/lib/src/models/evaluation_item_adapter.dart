import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationChoice,
        EvaluationItemKind,
        EvaluationItemValue,
        EvaluationRatingScale,
        EvaluationRatingStyle;

/// The adapter between the SDK's template item variants and the ui_lib
/// item form's `EvaluationItemValue` (form rules 7, 18), both ways, for
/// every variant.
///
/// A rating's labelled levels run 1..n by order; stars and a range carry
/// their bounds; `requireCommentFor` is typed per kind — `int` levels,
/// `bool` yes / no, `String` choice values, `num` numbers.
abstract final class EvaluationItemAdapter {
  /// [item] as the form-local value.
  static EvaluationItemValue toValue(sdk.EvaluationTemplateItem item) =>
      switch (item) {
        sdk.EvaluationInfoItem() => EvaluationItemValue(
          kind: EvaluationItemKind.info,
          id: item.id,
          text: item.markdown,
          isPrivate: item.isPrivate,
        ),
        sdk.EvaluationQuestionItem() => questionValue(item),
      };

  /// A question [item] as the form-local value.
  static EvaluationItemValue questionValue(sdk.EvaluationQuestionItem item) {
    final base = EvaluationItemValue(
      kind: kindOf(item.type),
      id: item.id,
      originItemId: item.originItemId,
      text: item.question,
      isPrivate: item.isPrivate,
      isRequired: item.isRequired,
      allowEvidence: item.allowEvidence,
    );
    return switch (item) {
      sdk.EvaluationRatingItem() => base.copyWith(
        showCommentArea: item.showCommentArea,
        requireCommentFor: List<Object>.of(item.requireCommentFor),
        scale: () => scaleOf(item),
      ),
      sdk.EvaluationYesNoItem() => base.copyWith(
        showCommentArea: item.showCommentArea,
        requireCommentFor: List<Object>.of(item.requireCommentFor),
        labelTrue: () => item.labelTrue,
        labelFalse: () => item.labelFalse,
      ),
      sdk.EvaluationChoiceItem() => base.copyWith(
        showCommentArea: item.showCommentArea,
        requireCommentFor: List<Object>.of(item.requireCommentFor),
        choices: [
          for (final c in item.choices)
            EvaluationChoice(value: c.value, text: c.text),
        ],
      ),
      sdk.EvaluationNumberItem() => base.copyWith(
        showCommentArea: item.showCommentArea,
        requireCommentFor: List<Object>.of(item.requireCommentFor),
      ),
      sdk.EvaluationQaItem() => base,
    };
  }

  /// [value] as the SDK variant its kind names; [value]'s id and origin
  /// carry over (the server ignores the id on input).
  static sdk.EvaluationTemplateItem toSdk(EvaluationItemValue value) {
    final v = value;
    final note = v.kind.hasCommentArea && v.showCommentArea;
    return switch (v.kind) {
      EvaluationItemKind.rating => ratingItem(v, showCommentArea: note),
      EvaluationItemKind.yesNo => sdk.EvaluationYesNoItem(
        id: v.id,
        question: v.text,
        isPrivate: v.isPrivate,
        isRequired: v.isRequired,
        allowEvidence: v.allowEvidence,
        originItemId: v.originItemId,
        showCommentArea: note,
        requireCommentFor: v.requireCommentFor.whereType<bool>().toList(),
        labelTrue: v.labelTrue,
        labelFalse: v.labelFalse,
      ),
      EvaluationItemKind.singleChoice => sdk.EvaluationSingleChoiceItem(
        id: v.id,
        question: v.text,
        isPrivate: v.isPrivate,
        isRequired: v.isRequired,
        allowEvidence: v.allowEvidence,
        originItemId: v.originItemId,
        showCommentArea: note,
        requireCommentFor: v.requireCommentFor.whereType<String>().toList(),
        choices: sdkChoices(v),
      ),
      EvaluationItemKind.multipleChoice => sdk.EvaluationMultipleChoiceItem(
        id: v.id,
        question: v.text,
        isPrivate: v.isPrivate,
        isRequired: v.isRequired,
        allowEvidence: v.allowEvidence,
        originItemId: v.originItemId,
        showCommentArea: note,
        requireCommentFor: v.requireCommentFor.whereType<String>().toList(),
        choices: sdkChoices(v),
      ),
      EvaluationItemKind.number => sdk.EvaluationNumberItem(
        id: v.id,
        question: v.text,
        isPrivate: v.isPrivate,
        isRequired: v.isRequired,
        allowEvidence: v.allowEvidence,
        originItemId: v.originItemId,
        showCommentArea: note,
        requireCommentFor: v.requireCommentFor.whereType<num>().toList(),
      ),
      EvaluationItemKind.qa => sdk.EvaluationQaItem(
        id: v.id,
        question: v.text,
        isPrivate: v.isPrivate,
        isRequired: v.isRequired,
        allowEvidence: v.allowEvidence,
        originItemId: v.originItemId,
      ),
      EvaluationItemKind.info => sdk.EvaluationInfoItem(
        id: v.id,
        markdown: v.text,
        isPrivate: v.isPrivate,
      ),
    };
  }

  /// A rating [v] as the SDK variant: levels as `rateValues` 1..n, stars
  /// as `rateType` with bounds, a range as bounds alone.
  static sdk.EvaluationRatingItem ratingItem(
    EvaluationItemValue v, {
    required bool showCommentArea,
  }) {
    final scale = v.scale ?? const EvaluationRatingScale.stars();
    final levels = scale.isLevels;
    return sdk.EvaluationRatingItem(
      id: v.id,
      question: v.text,
      isPrivate: v.isPrivate,
      isRequired: v.isRequired,
      allowEvidence: v.allowEvidence,
      originItemId: v.originItemId,
      showCommentArea: showCommentArea,
      requireCommentFor: v.requireCommentFor.whereType<int>().toList(),
      rateType: scale.style == EvaluationRatingStyle.stars
          ? sdk.EvaluationRateType.stars
          : null,
      rateMin: levels ? null : scale.min,
      rateMax: levels ? null : scale.max,
      rateValues: levels
          ? [
              for (final (i, text) in scale.levels.indexed)
                sdk.EvaluationRateLevel(value: i + 1, text: text),
            ]
          : null,
    );
  }

  /// A rating's scale: labelled levels when it has them, else stars or a
  /// range over its bounds (1..5 when absent).
  static EvaluationRatingScale scaleOf(sdk.EvaluationRatingItem item) {
    final levels = item.rateValues;
    if (levels != null) {
      final sorted = [...levels]..sort((a, b) => a.value.compareTo(b.value));
      return EvaluationRatingScale.levels([for (final l in sorted) l.text]);
    }
    final min = item.rateMin ?? EvaluationRatingScale.defaultMin;
    final max = item.rateMax ?? EvaluationRatingScale.defaultMax;
    return item.rateType == sdk.EvaluationRateType.stars
        ? EvaluationRatingScale.stars(min: min, max: max)
        : EvaluationRatingScale.range(min: min, max: max);
  }

  /// [v]'s choices as the SDK's.
  static List<sdk.EvaluationChoice> sdkChoices(EvaluationItemValue v) => [
    for (final c in v.choices)
      sdk.EvaluationChoice(value: c.value, text: c.text),
  ];

  /// The form-local kind of SDK [type].
  static EvaluationItemKind kindOf(sdk.EvaluationItemType type) =>
      switch (type) {
        sdk.EvaluationItemType.rating => EvaluationItemKind.rating,
        sdk.EvaluationItemType.yesNo => EvaluationItemKind.yesNo,
        sdk.EvaluationItemType.singleChoice => EvaluationItemKind.singleChoice,
        sdk.EvaluationItemType.multipleChoice =>
          EvaluationItemKind.multipleChoice,
        sdk.EvaluationItemType.number => EvaluationItemKind.number,
        sdk.EvaluationItemType.qa => EvaluationItemKind.qa,
        sdk.EvaluationItemType.info => EvaluationItemKind.info,
      };

  /// The SDK type of form-local [kind].
  static sdk.EvaluationItemType typeOf(EvaluationItemKind kind) =>
      switch (kind) {
        EvaluationItemKind.rating => sdk.EvaluationItemType.rating,
        EvaluationItemKind.yesNo => sdk.EvaluationItemType.yesNo,
        EvaluationItemKind.singleChoice => sdk.EvaluationItemType.singleChoice,
        EvaluationItemKind.multipleChoice =>
          sdk.EvaluationItemType.multipleChoice,
        EvaluationItemKind.number => sdk.EvaluationItemType.number,
        EvaluationItemKind.qa => sdk.EvaluationItemType.qa,
        EvaluationItemKind.info => sdk.EvaluationItemType.info,
      };

  /// A new copy of [item] to add to another template: no id, and its
  /// origin the source's origin, else the source — never a copy of a copy.
  static EvaluationItemValue copyOf(sdk.EvaluationTemplateItem item) {
    final value = toValue(item);
    final origin = item is sdk.EvaluationQuestionItem
        ? item.originItemId ?? item.id
        : null;
    return value.copyWith(id: () => null, originItemId: () => origin);
  }

  /// [edited] — what the item form returned for [before] — with
  /// [before]'s id and origin back. For a copy, its choices keep
  /// [before]'s values by position whatever their labels became, and the
  /// coach-note rule follows them, so relabelling a copy keeps its origin's
  /// answer domain; added choices keep their derived values (the server may
  /// refuse them, `ORIGIN_MISMATCH`).
  static EvaluationItemValue keepOrigin(
    EvaluationItemValue before,
    EvaluationItemValue edited,
  ) {
    final restored = edited.copyWith(
      id: () => before.id,
      originItemId: () => before.originItemId,
    );
    if (before.originItemId == null || !restored.kind.hasChoices) {
      return restored;
    }
    final old = before.choices;
    final choices = [
      for (final (i, c) in restored.choices.indexed)
        if (i < old.length) c.copyWith(value: old[i].value) else c,
    ];
    final renamed = {
      for (final (i, c) in restored.choices.indexed) c.value: choices[i].value,
    };
    return restored.copyWith(
      choices: choices,
      requireCommentFor: [
        for (final v in restored.requireCommentFor) renamed[v] ?? v,
      ],
    );
  }
}
