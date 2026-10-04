import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import 'evaluation_label_row.dart';

/// Edits a list of labels — a rating's levels or a question's choices. The
/// designer types labels only: levels are valued 1..n by their order
/// ([numbered] shows the numbers), choice values derive from the labels.
class EvaluationLabelListEditor extends StatelessWidget {
  /// Edits [labels].
  const EvaluationLabelListEditor({
    required this.labels,
    required this.addLabel,
    required this.onChanged,
    this.numbered = false,
    super.key,
  });

  /// The labels, in order.
  final List<String> labels;

  /// Text of the button adding a row, e.g. "Level".
  final String addLabel;

  /// Called with the edited list.
  final ValueChanged<List<String>> onChanged;

  /// Whether each row shows its 1-based number (levels).
  final bool numbered;

  /// [labels] with [edit] applied to a copy.
  List<String> edited(void Function(List<String> list) edit) {
    final list = [...labels];
    edit(list);
    return list;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: EvaluationSpacing.smallGap,
    children: [
      for (final (i, label) in labels.indexed)
        EvaluationLabelRow(
          key: ValueKey(i),
          label: label,
          number: numbered ? i + 1 : null,
          onChanged: (text) => onChanged(edited((l) => l[i] = text)),
          onRemove: () => onChanged(edited((l) => l.removeAt(i))),
          onMoveUp: i == 0
              ? null
              : () => onChanged(edited((l) => l.insert(i - 1, l.removeAt(i)))),
          onMoveDown: i == labels.length - 1
              ? null
              : () => onChanged(edited((l) => l.insert(i + 1, l.removeAt(i)))),
        ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ShadButton.outline(
          leading: const Icon(LucideIcons.plus),
          onPressed: () => onChanged([...labels, '']),
          child: Text(addLabel),
        ),
      ),
    ],
  );
}
