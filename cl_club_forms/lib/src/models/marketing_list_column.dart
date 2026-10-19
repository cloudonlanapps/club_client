import 'package:flutter/widgets.dart';

import 'marketing_list_column_kind.dart';

/// One column of a marketing list editor: the key its value is held under
/// in a row, its label and the input it shows.
///
/// A row is a `Map<String, Object?>`: a `String` under a text, multiline,
/// number or choice column (empty when blank or not chosen), a `DateTime?`
/// under a date column.
@immutable
class MarketingListColumn {
  const MarketingListColumn({
    required this.id,
    required this.label,
    this.kind = MarketingListColumnKind.text,
    this.placeholder,
    this.keyboardType,
    this.options = const [],
    this.flex = 1,
  });

  /// The key of the column's value in a row.
  final String id;

  /// The label above the column's input.
  final String label;

  /// What the column holds.
  final MarketingListColumnKind kind;

  /// The hint shown in an empty input.
  final String? placeholder;

  /// The keyboard of a text input; a number column always takes digits.
  final TextInputType? keyboardType;

  /// The values a choice column offers, in order.
  final List<String> options;

  /// The column's share of a wide row.
  final int flex;

  /// The value of the column in a new row.
  Object? get emptyValue => kind == MarketingListColumnKind.date ? null : '';
}
