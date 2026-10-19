import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/marketing_list_column.dart';
import '../../models/marketing_list_column_kind.dart';
import 'marketing_list_row.dart';

/// Edits a list of marketing rows (fee items, packages, offers, facilities,
/// highlights): one [MarketingListRow] per row, and a button that adds one
/// while there are fewer than [maxRows].
///
/// It reports the whole list through [onChanged] on every edit. Each row
/// is a `Map<String, Object?>` keyed by column id (see
/// [MarketingListColumn]); the list is seeded once from [initialRows].
class MarketingListEditor extends StatefulWidget {
  const MarketingListEditor({
    required this.columns,
    required this.initialRows,
    required this.onChanged,
    required this.addLabel,
    required this.maxRows,
    this.enabled = true,
    super.key,
  });

  /// The columns of every row, in order.
  final List<MarketingListColumn> columns;

  /// The rows to start from.
  final List<Map<String, Object?>> initialRows;

  /// Called with the rows after every edit.
  final ValueChanged<List<Map<String, Object?>>> onChanged;

  /// The text of the add button.
  final String addLabel;

  /// The most rows the list may hold.
  final int maxRows;

  /// Whether the editor takes input.
  final bool enabled;

  @override
  State<MarketingListEditor> createState() => MarketingListEditorState();
}

/// State of [MarketingListEditor]: the rows, each with a key that survives
/// removals above it and the text controllers of its text cells.
class MarketingListEditorState extends State<MarketingListEditor> {
  /// The rows, in order.
  final List<Map<String, Object?>> rows = [];

  /// The key of each row, in the order of [rows].
  final List<int> rowKeys = [];

  /// The text controllers of each row, by row key and column id.
  final Map<int, Map<String, TextEditingController>> controllers = {};

  /// The key the next row takes.
  int nextKey = 0;

  @override
  void initState() {
    super.initState();
    widget.initialRows.forEach(addRowFrom);
  }

  @override
  void dispose() {
    for (final row in controllers.values) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  /// Whether [column] types into a text controller.
  bool isTyped(MarketingListColumn column) =>
      column.kind != MarketingListColumnKind.date &&
      column.kind != MarketingListColumnKind.choice;

  /// Appends [row], with a controller for each typed cell.
  void addRowFrom(Map<String, Object?> row) {
    final key = nextKey++;
    final value = {
      for (final column in widget.columns)
        column.id: row[column.id] ?? column.emptyValue,
    };
    rows.add(value);
    rowKeys.add(key);
    controllers[key] = {
      for (final column in widget.columns)
        if (isTyped(column))
          column.id: TextEditingController(
            text: value[column.id] as String? ?? '',
          ),
    };
  }

  /// Reports the rows, each a copy.
  void report() => widget.onChanged([for (final row in rows) Map.of(row)]);

  /// Adds an empty row.
  void addRow() {
    setState(() => addRowFrom(const {}));
    report();
  }

  /// Removes the row at [index].
  void removeRow(int index) {
    setState(() {
      final key = rowKeys.removeAt(index);
      rows.removeAt(index);
      for (final controller in controllers.remove(key)!.values) {
        controller.dispose();
      }
    });
    report();
  }

  /// Sets the cell of [columnId] in the row at [index] to [value].
  void updateCell(int index, String columnId, Object? value) {
    setState(() => rows[index][columnId] = value);
    report();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        for (var i = 0; i < rows.length; i++)
          MarketingListRow(
            key: ValueKey<int>(rowKeys[i]),
            columns: widget.columns,
            value: rows[i],
            controllers: controllers[rowKeys[i]]!,
            enabled: widget.enabled,
            onChanged: (columnId, value) => updateCell(i, columnId, value),
            onRemove: () => removeRow(i),
          ),
        if (rows.length < widget.maxRows)
          Align(
            alignment: Alignment.centerLeft,
            child: ShadButton.outline(
              enabled: widget.enabled,
              leading: const Icon(LucideIcons.plus, size: 16),
              onPressed: addRow,
              child: Text(widget.addLabel),
            ),
          ),
      ],
    );
  }
}
