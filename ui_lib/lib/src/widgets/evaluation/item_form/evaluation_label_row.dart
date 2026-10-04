import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../common/evaluation_icon_action.dart';

/// One editable label of a level or choice list, with its level number in
/// front when [number] is given, and move / remove actions.
///
/// Stateful only to own its controller; the host's [label] replaces the
/// text only when the two disagree, so typing is not interrupted.
class EvaluationLabelRow extends StatefulWidget {
  /// Edits [label].
  const EvaluationLabelRow({
    required this.label,
    required this.onChanged,
    required this.onRemove,
    this.number,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  /// The label.
  final String label;

  /// Called with the edited label.
  final ValueChanged<String> onChanged;

  /// Removes the row.
  final VoidCallback onRemove;

  /// A level's value, shown before the label; `null` for a choice.
  final int? number;

  /// Moves the row up; `null` when first.
  final VoidCallback? onMoveUp;

  /// Moves the row down; `null` when last.
  final VoidCallback? onMoveDown;

  @override
  State<EvaluationLabelRow> createState() => EvaluationLabelRowState();
}

/// State of [EvaluationLabelRow]: the controller.
class EvaluationLabelRowState extends State<EvaluationLabelRow> {
  /// The input's controller.
  late final TextEditingController controller = TextEditingController(
    text: widget.label,
  );

  @override
  void didUpdateWidget(EvaluationLabelRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller.text != widget.label) controller.text = widget.label;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.number;
    return Row(
      spacing: EvaluationSpacing.smallGap,
      children: [
        if (number != null)
          SizedBox(
            width: EvaluationSpacing.ordinalWidth,
            child: Text(
              '$number',
              style: ShadTheme.of(context).textTheme.muted,
            ),
          ),
        Expanded(
          child: ShadInput(
            controller: controller,
            placeholder: const Text(EvaluationStrings.labelPlaceholder),
            onChanged: widget.onChanged,
          ),
        ),
        EvaluationIconAction(
          label: EvaluationStrings.moveUp,
          icon: LucideIcons.arrowUp,
          onPressed: widget.onMoveUp,
        ),
        EvaluationIconAction(
          label: EvaluationStrings.moveDown,
          icon: LucideIcons.arrowDown,
          onPressed: widget.onMoveDown,
        ),
        EvaluationIconAction(
          label: EvaluationStrings.delete,
          icon: LucideIcons.x,
          onPressed: widget.onRemove,
        ),
      ],
    );
  }
}
