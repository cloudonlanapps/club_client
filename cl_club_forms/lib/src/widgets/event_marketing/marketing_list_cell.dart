import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/marketing_list_column.dart';
import '../../models/marketing_list_column_kind.dart';
import 'marketing_list_date_cell.dart';

/// One cell of a marketing list row: the input its column's kind calls for.
///
/// A text, multiline or number cell types into [controller]; a date or
/// choice cell reports through [onChanged].
class MarketingListCell extends StatelessWidget {
  const MarketingListCell({
    required this.column,
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.controller,
    super.key,
  });

  /// Lines a multiline cell shows at least.
  static const int multilineMinLines = 2;

  /// Lines a multiline cell grows to before it scrolls.
  static const int multilineMaxLines = 5;

  /// The cell's column.
  final MarketingListColumn column;

  /// The cell's value: a `String`, or a `DateTime?` for a date.
  final Object? value;

  /// Called with the cell's new value.
  final ValueChanged<Object?> onChanged;

  /// Whether the cell takes input.
  final bool enabled;

  /// The text of a text, multiline or number cell.
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    switch (column.kind) {
      case MarketingListColumnKind.date:
        return MarketingListDateCell(
          value: value as DateTime?,
          onChanged: onChanged,
          enabled: enabled,
          placeholder: column.placeholder,
        );
      case MarketingListColumnKind.choice:
        final chosen = value as String? ?? '';
        return ShadSelect<String>(
          enabled: enabled,
          initialValue: chosen.isEmpty ? null : chosen,
          placeholder: Text(column.placeholder ?? ''),
          allowDeselection: true,
          options: [
            for (final option in column.options)
              ShadOption(value: option, child: Text(option)),
          ],
          selectedOptionBuilder: (context, option) => Text(option),
          onChanged: (option) => onChanged(option ?? ''),
        );
      case MarketingListColumnKind.text:
      case MarketingListColumnKind.multiline:
      case MarketingListColumnKind.number:
        final multiline = column.kind == MarketingListColumnKind.multiline;
        final number = column.kind == MarketingListColumnKind.number;
        return ShadInput(
          controller: controller,
          enabled: enabled,
          placeholder: column.placeholder == null
              ? null
              : Text(column.placeholder!),
          keyboardType: number
              ? TextInputType.number
              : multiline
              ? TextInputType.multiline
              : column.keyboardType,
          inputFormatters: number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          minLines: multiline ? multilineMinLines : null,
          maxLines: multiline ? multilineMaxLines : 1,
          onChanged: onChanged,
        );
    }
  }
}
