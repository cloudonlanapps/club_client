import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../../models/evaluation_layout_position.dart';
import '../../../utils/evaluation_layout_ops.dart';
import '../../../utils/evaluation_outline_text.dart';
import 'evaluation_add_bar.dart';
import 'evaluation_outline_row.dart';

/// The rows of the layout outline: each entry, and under a section header
/// its items, indented. Reports what the designer does with a row; the
/// editor turns that into a new layout.
class EvaluationOutlineRows extends StatelessWidget {
  /// Rows for [layout].
  const EvaluationOutlineRows({
    required this.layout,
    required this.sorting,
    required this.readOnly,
    required this.onEditItem,
    required this.onEditSection,
    required this.onMove,
    required this.onAddToSection,
    this.onAddExistingToSection,
    this.enabled = true,
    super.key,
  });

  /// The items and sections, in order.
  final List<EvaluationLayoutEntry> layout;

  /// Whether the reorder arrows show.
  final bool sorting;

  /// Hides the sections' "+".
  final bool readOnly;

  /// Opens the item at a position; `null` leaves item rows inert.
  final ValueChanged<EvaluationLayoutPosition>? onEditItem;

  /// Retitles the section at an index; `null` leaves section rows inert.
  final ValueChanged<int>? onEditSection;

  /// Moves the row at a position by −1 or +1.
  final void Function(EvaluationLayoutPosition pos, int delta) onMove;

  /// Adds an item of a kind into the section at an index.
  final void Function(EvaluationItemKind kind, int section) onAddToSection;

  /// Adds an existing question into the section at an index; `null` hides
  /// the option.
  final ValueChanged<int>? onAddExistingToSection;

  /// Whether the arrows and the sections' "+" answer; off, they show
  /// greyed.
  final bool enabled;

  /// The move callback for [pos] by [delta], or `null` when it cannot move.
  VoidCallback? mover(EvaluationLayoutPosition pos, int delta) =>
      !enabled || EvaluationLayoutOps.move(layout, pos, delta) == null
      ? null
      : () => onMove(pos, delta);

  @override
  Widget build(BuildContext context) {
    final muted = ShadTheme.of(context).textTheme.muted;
    final existing = onAddExistingToSection;
    final editItem = onEditItem;
    final editSection = onEditSection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.smallGap,
      children: [
        for (final pos in EvaluationLayoutOps.positions(layout))
          if (EvaluationLayoutOps.itemAt(layout, pos) case final item?)
            EvaluationOutlineRow(
              caption: EvaluationOutlineText.captionOf(item),
              title: EvaluationOutlineText.titleOf(item),
              indented: pos.isInSection,
              showArrows: sorting,
              onTap: editItem == null ? null : () => editItem(pos),
              onMoveUp: mover(pos, -1),
              onMoveDown: mover(pos, 1),
            )
          else ...[
            EvaluationOutlineRow(
              caption: EvaluationStrings.section,
              title: layout[pos.entry].sectionTitle!,
              emphasised: true,
              showArrows: sorting,
              onTap: editSection == null ? null : () => editSection(pos.entry),
              onMoveUp: mover(pos, -1),
              onMoveDown: mover(pos, 1),
              trailing: readOnly
                  ? null
                  : EvaluationAddBar(
                      compact: true,
                      enabled: enabled,
                      onAddItem: (kind) => onAddToSection(kind, pos.entry),
                      onAddExisting: existing == null
                          ? null
                          : () => existing(pos.entry),
                    ),
            ),
            if (layout[pos.entry].sectionItems.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: EvaluationSpacing.indent,
                ),
                child: Text(EvaluationStrings.emptySection, style: muted),
              ),
          ],
      ],
    );
  }
}
