import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_rating_style.dart';
import '../../../utils/evaluation_answer_rules.dart';
import '../../labeled_form_row.dart';
import '../common/evaluation_form_body.dart';
import '../common/evaluation_form_contract.dart';
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
/// [enabled] off is for the time a save takes: the fields grey and take no
/// change. [readOnly] is for a viewer who may not edit: it shows the item
/// with every field disabled (a frozen template).
class EvaluationItemForm extends StatefulWidget {
  /// Edits an item of [kind] seeded with [initialValues] (see
  /// [EvaluationItemFormValues.fromItem]).
  const EvaluationItemForm({
    required this.kind,
    required this.initialValues,
    this.readOnly = false,
    this.enabled = true,
    super.key,
  });

  /// The item's kind; fixed for the editor's life.
  final EvaluationItemKind kind;

  /// The form's initial values, keyed by [EvaluationItemFormFields].
  final Map<String, dynamic> initialValues;

  /// Whether the fields are shown without accepting changes.
  final bool readOnly;

  /// Whether the fields can change (off while the host saves).
  final bool enabled;

  @override
  State<EvaluationItemForm> createState() => EvaluationItemFormState();
}

/// State of [EvaluationItemForm]: the form, and its values as of the last
/// change, which decide the dependent fields.
class EvaluationItemFormState extends State<EvaluationItemForm>
    with
        EvaluationFormFocus<EvaluationItemForm>,
        EvaluationFormContract<EvaluationItemForm> {
  /// The form's values as of the last change.
  late Map<String, dynamic> values = widget.initialValues;

  // Custom fields own no focusable input, so nothing is focused.
  @override
  bool get focusFirstInvalid => false;

  /// The item's values: [EvaluationItemFormFields.textId]
  /// trimmed, the switches, the coach-note rule limited to answers the
  /// question can take (empty without the comment area), and the kind's own
  /// fields — `ratingStyleId` with `rateMinId` / `rateMaxId` as `int`s or
  /// `levelsId`; `labelTrueId` / `labelFalseId` as `String?`; `choicesId`
  /// as `List<EvaluationChoice>` valued from the labels.
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final kind = widget.kind;
    final item = EvaluationItemFormValues.toItem(values, kind: kind);
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

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final readOnly = widget.readOnly;
    final form = ShadForm(
      key: formKey,
      enabled: widget.enabled && !readOnly,
      initialValue: widget.initialValues,
      onChanged: () => setState(() => values = formKey.currentState!.value),
      child: EvaluationFormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: kind.isQuestion
                ? EvaluationStrings.question
                : EvaluationStrings.infoText,
            required: true,
            field: ShadTextareaFormField(
              id: EvaluationItemFormFields.textId,
              validator: kind.isQuestion
                  ? EvaluationItemFormValidators.question
                  : EvaluationItemFormValidators.infoText,
            ),
          ),
          if (kind.hasKindFields)
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
