import '../../models/marketing_list_column.dart';
import '../../models/marketing_list_column_kind.dart';
import 'marketing_rows.dart';

/// Validators of the event marketing forms.
abstract final class EventMarketingFormValidators {
  /// A text of at most [max] characters, blank allowed.
  static String? Function(String?) maxLength(int max) =>
      (value) =>
          (value?.trim().length ?? 0) > max ? 'At most $max characters.' : null;

  /// Rows whose [required] columns are filled, whose text columns stay
  /// within [maxLengths] (by column id), and whose number columns are whole
  /// numbers. Blank rows are dropped on save, so they pass.
  static String? Function(List<Object?>?) rows({
    required List<MarketingListColumn> columns,
    Set<String> required = const {},
    Map<String, int> maxLengths = const {},
  }) => (rows) {
    for (final row in asMarketingRows(rows)) {
      if (isBlankRow(row)) continue;
      for (final column in columns) {
        final value = row[column.id];
        final text = value is String ? value.trim() : '';
        final hasValue = value is DateTime || text.isNotEmpty;
        if (required.contains(column.id) && !hasValue) {
          return 'Every row needs a ${column.label.toLowerCase()}.';
        }
        final max = maxLengths[column.id];
        if (max != null && text.length > max) {
          return '${column.label} is at most $max characters.';
        }
        if (column.kind == MarketingListColumnKind.number &&
            text.isNotEmpty &&
            int.tryParse(text) == null) {
          return '${column.label} must be a whole number.';
        }
      }
    }
    return null;
  };

  /// A whole number of rupees, blank allowed.
  static String? wholeAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return int.tryParse(text) == null ? 'A whole number.' : null;
  }

  /// Whether [row] holds nothing.
  static bool isBlankRow(Map<String, Object?> row) => row.values.every(
    (value) => value == null || (value is String && value.trim().isEmpty),
  );
}
