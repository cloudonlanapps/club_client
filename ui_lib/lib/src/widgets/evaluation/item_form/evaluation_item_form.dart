import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_rating_style.dart';
import '../../../utils/evaluation_answer_rules.dart';
import '../../../utils/evaluation_form_equality.dart';
import '../common/evaluation_form_focus.dart';
import 'evaluation_item_form_fields.dart';
import 'evaluation_item_form_validators.dart';
import 'evaluation_item_form_values.dart';
import 'evaluation_item_kind_fields.dart';
import 'evaluation_item_switches.dart';

/// Pure-UI editor of one evaluation template item of [kind] (no SDK, no
/// Riverpod): the question (or an info text's markdown), the kind's own
/// fields, and the switches. One field per input, keyed by
/// [EvaluationItemFormFields].
///
/// Owns no dialog and no buttons: the host builds the dialog and drives the
/// form through a `GlobalKey<EvaluationItemFormState>`, calling
/// [EvaluationItemFormState.validate] from its Save action.
/// [EvaluationItemFormValues] converts to and from `EvaluationItemValue`.
/// [readOnly] shows the item with every field disabled (a frozen template).
class EvaluationItemForm extends StatefulWidget {
  /// Edits an item of [kind] seeded with [initialValues] (see
  /// [EvaluationItemFormValues.fromItem]).
  const EvaluationItemForm({
    required this.kind,
    required this.initialValues,
    this.readOnly = false,
    super.key,
  });

  /// The item's kind; fixed for the editor's life.
  final EvaluationItemKind kind;

  /// The form's initial values, keyed by [EvaluationItemFormFields].
  final Map<String, dynamic> initialValues;

  /// Whether the fields are shown without accepting changes.
  final bool readOnly;

  @override
  State<EvaluationItemForm> createState() => EvaluationItemFormState();
}

/// State of [EvaluationItemForm]: the form, and its values as of the last
/// change, which decide the dependent fields.
class EvaluationItemFormState extends State<EvaluationItemForm>
    with EvaluationFormFocus<EvaluationItemForm> {
  /// The form.
  final GlobalKey<ShadFormState> formKey = GlobalKey<ShadFormState>();

  /// The form's values as of the last change.
  late Map<String, dynamic> values = widget.initialValues;

  /// Validates every field, showing errors under them. Returns the item's
  /// values when valid, else `null`: [EvaluationItemFormFields.textId]
  /// trimmed, the switches, the coach-note rule limited to answers the
  /// question can take (empty without the comment area), and the kind's own
  /// fields — `ratingStyleId` with `rateMinId` / `rateMaxId` as `int`s or
  /// `levelsId`; `labelTrueId` / `labelFalseId` as `String?`; `choicesId`
  /// as `List<EvaluationChoice>` valued from the labels.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    // Custom fields own no focusable input, so nothing is focused.
    if (form == null || !form.saveAndValidate(focusOnInvalid: false)) {
      return null;
    }
    final kind = widget.kind;
    final item = EvaluationItemFormValues.toItem(form.value, kind: kind);
    final offered = {
      for (final (v, _) in EvaluationAnswerRules.answerOptions(item) ?? []) v,
    };
    final scale = item.scale;
    return {
      EvaluationItemFormFields.textId: item.text,
      EvaluationItemFormFields.isRequiredId: item.isRequired,
      EvaluationItemFormFields.isPrivateId: item.isPrivate,
      EvaluationItemFormFields.allowEvidenceId: item.allowEvidence,
      EvaluationItemFormFields.showCommentAreaId: item.showCommentArea,
      EvaluationItemFormFields.requireCommentForId: [
        for (final v in item.requireCommentFor)
          if (offered.contains(v)) v,
      ],
      if (scale != null) ...{
        EvaluationItemFormFields.ratingStyleId: scale.style,
        if (scale.style == EvaluationRatingStyle.levels)
          EvaluationItemFormFields.levelsId: scale.levels
        else ...{
          EvaluationItemFormFields.rateMinId: scale.min,
          EvaluationItemFormFields.rateMaxId: scale.max,
        },
      },
      if (kind == EvaluationItemKind.yesNo) ...{
        EvaluationItemFormFields.labelTrueId: item.labelTrue,
        EvaluationItemFormFields.labelFalseId: item.labelFalse,
      },
      if (kind.hasChoices) EvaluationItemFormFields.choicesId: item.choices,
    };
  }

  /// Whether any field differs from the initial values.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !EvaluationFormEquality.mapsEqual(form.initialValue, form.value);
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final readOnly = widget.readOnly;
    final form = ShadForm(
      key: formKey,
      enabled: !readOnly,
      initialValue: widget.initialValues,
      onChanged: () => setState(() => values = formKey.currentState!.value),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: EvaluationSpacing.fieldGap,
        children: [
          ShadTextareaFormField(
            id: EvaluationItemFormFields.textId,
            label: Text(
              kind.isQuestion
                  ? EvaluationStrings.question
                  : EvaluationStrings.infoText,
            ),
            validator: kind.isQuestion
                ? EvaluationItemFormValidators.question
                : EvaluationItemFormValidators.infoText,
          ),
          EvaluationItemKindFields(kind: kind, values: values),
          EvaluationItemSwitches(kind: kind, values: values),
        ],
      ),
    );
    // Some fields build their own controls; absorbing taps keeps those
    // still too, while the dialog around the form can scroll.
    return readOnly ? AbsorbPointer(child: form) : form;
  }
}
