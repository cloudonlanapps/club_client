import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_answer_value.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../../utils/evaluation_answer_rules.dart';
import '../common/evaluation_layout_view.dart';
import '../common/evaluation_markdown_text.dart';
import '../common/evaluation_private_shade.dart';
import 'evaluation_fill_form_fields.dart';
import 'evaluation_question_form_field.dart';

/// Pure-UI form filling an evaluation against its template's [layout] (no
/// SDK, no Riverpod). Sections show as titled cards; each question is one
/// ShadForm field (keyed by [EvaluationFillFormFields.idFor]) with its answer
/// input, a coach note where the item shows a comment area, and the host's
/// [evidenceBuilder] slot where the item allows evidence.
///
/// The form owns the answers once seeded with [initialAnswers]; every change
/// is reported through [onAnswerChanged] so the host can autosave (give the
/// form a new key to reload). A draft may have gaps: the host calls
/// [EvaluationFillFormState.validateForSave] only before saving — or, with
/// [validateOnOpen], at once too, so a reopened draft shows its gaps (each
/// clears as it is filled). [readOnly] shows a saved or published
/// evaluation without inputs that respond, its private items greyed (what
/// the member will not see); an editable form shows them normally. The run
/// of Q & A items closing the layout shows last, outside any section, in
/// one untitled card. Every item in [layout] must carry its id.
class EvaluationFillForm extends StatefulWidget {
  /// Fills [layout], seeded with [initialAnswers] keyed by item id.
  const EvaluationFillForm({
    required this.layout,
    required this.initialAnswers,
    required this.onAnswerChanged,
    this.evidenceBuilder,
    this.readOnly = false,
    this.validateOnOpen = false,
    super.key,
  });

  /// The template's items and sections, items with ids.
  final List<EvaluationLayoutEntry> layout;

  /// The answers so far, by item id.
  final Map<int, EvaluationAnswerValue> initialAnswers;

  /// Called with the item's id and its whole answer after each change.
  final void Function(int itemId, EvaluationAnswerValue answer) onAnswerChanged;

  /// Builds the evidence slot of an item that allows evidence.
  final Widget Function(int itemId)? evidenceBuilder;

  /// Whether the answers are shown without accepting changes.
  final bool readOnly;

  /// Whether the gaps — required answers and coach notes — show as soon as
  /// the form opens.
  final bool validateOnOpen;

  @override
  State<EvaluationFillForm> createState() => EvaluationFillFormState();
}

/// State of [EvaluationFillForm]: the form holding every answer.
class EvaluationFillFormState extends State<EvaluationFillForm> {
  /// The form.
  final GlobalKey<ShadFormState> formKey = GlobalKey<ShadFormState>();

  /// The answers as they stand, by item id.
  Map<int, EvaluationAnswerValue> get answers {
    final values = formKey.currentState?.value ?? const {};
    return {
      for (final item in EvaluationLayoutEntry.flatten(widget.layout))
        if (item.kind.isQuestion)
          item.id!:
              values[EvaluationFillFormFields.idFor(item.id!)]
                  as EvaluationAnswerValue? ??
              const EvaluationAnswerValue(),
    };
  }

  @override
  void initState() {
    super.initState();
    if (widget.validateOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          formKey.currentState?.validate(focusOnInvalid: false);
        }
      });
    }
  }

  /// Validates every question for saving, showing errors under them, and
  /// returns the ids of the items that block it — a required question
  /// without an answer, or an answer whose coach note is required and
  /// missing — in layout order. Empty means the evaluation can be saved.
  List<int> validateForSave() {
    // Custom fields own no focusable input: scroll to the first error
    // rather than focusing it.
    formKey.currentState?.validate(
      focusOnInvalid: false,
      autoScrollWhenFocusOnInvalid: true,
    );
    final current = answers;
    return [
      for (final item in EvaluationLayoutEntry.flatten(widget.layout))
        if (item.kind.isQuestion &&
            EvaluationAnswerRules.validate(item, current[item.id]!) != null)
          item.id!,
    ];
  }

  /// Shows "Complete this answer." under each of [itemIds] — e.g. the items
  /// the server named when it refused to save.
  void markIncomplete(Iterable<int> itemIds) {
    final fields = formKey.currentState?.fields ?? const {};
    for (final id in itemIds) {
      fields[EvaluationFillFormFields.idFor(id)]?.setError(
        EvaluationStrings.incomplete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final evidence = widget.evidenceBuilder;
    return ShadForm(
      key: formKey,
      initialValue: {
        for (final MapEntry(:key, :value) in widget.initialAnswers.entries)
          EvaluationFillFormFields.idFor(key): value,
      },
      child: EvaluationLayoutView(
        layout: widget.layout,
        itemBuilder: (item) => EvaluationPrivateShade(
          muted: widget.readOnly && item.isPrivate,
          child: item.kind.isQuestion
              ? EvaluationQuestionFormField(
                  key: ValueKey(item.id),
                  item: item,
                  enabled: !widget.readOnly,
                  evidence: evidence != null && item.allowEvidence
                      ? evidence(item.id!)
                      : null,
                  onAnswerChanged: (answer) =>
                      widget.onAnswerChanged(item.id!, answer),
                )
              : EvaluationMarkdownText(data: item.text),
        ),
      ),
    );
  }
}
