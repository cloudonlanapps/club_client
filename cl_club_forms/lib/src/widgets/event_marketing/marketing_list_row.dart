import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_breakpoints.dart';
import '../../constants/form_spacing.dart';
import '../../models/marketing_list_column.dart';
import '../form/labeled_form_row.dart';
import 'marketing_list_cell.dart';

/// One row of a marketing list editor: a labelled cell per column and a
/// button that removes the row.
///
/// On a wide editor the cells sit side by side, each taking its column's
/// share; on a narrow one they stack.
class MarketingListRow extends StatelessWidget {
  const MarketingListRow({
    required this.columns,
    required this.value,
    required this.controllers,
    required this.onChanged,
    required this.onRemove,
    required this.enabled,
    super.key,
  });

  /// The row's padding inside its border.
  static const double padding = 12;

  /// The rounding of the row's border.
  static const double radius = 8;

  /// The columns, in order.
  final List<MarketingListColumn> columns;

  /// The row, keyed by column id.
  final Map<String, Object?> value;

  /// The text of each text, multiline and number cell, by column id.
  final Map<String, TextEditingController> controllers;

  /// Called with a column's id and its cell's new value.
  final void Function(String columnId, Object? value) onChanged;

  /// Removes the row.
  final VoidCallback onRemove;

  /// Whether the row takes input.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cells = [
      for (final column in columns)
        LabeledFormRow(
          label: column.label,
          field: MarketingListCell(
            column: column,
            value: value[column.id],
            controller: controllers[column.id],
            enabled: enabled,
            onChanged: (cell) => onChanged(column.id, cell),
          ),
        ),
    ];
    final remove = ShadIconButton.ghost(
      enabled: enabled,
      icon: const Icon(LucideIcons.trash2, size: 16),
      onPressed: onRemove,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < FormBreakpoints.singleColumnMaxWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FormSpacing.rowGap,
                children: [
                  ...cells,
                  Align(alignment: Alignment.centerRight, child: remove),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: FormSpacing.rowGap,
              children: [
                for (var i = 0; i < cells.length; i++)
                  Expanded(flex: columns[i].flex, child: cells[i]),
                remove,
              ],
            );
          },
        ),
      ),
    );
  }
}
