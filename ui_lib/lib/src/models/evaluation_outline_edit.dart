import 'package:flutter/foundation.dart';

/// What the host's dialog for one outline row resolved to: the edited
/// [value] (an item, or a section's title), or a request to delete the row.
/// A dialog that is cancelled resolves to `null` instead.
@immutable
class EvaluationOutlineEdit<T extends Object> {
  /// The row edited to [value].
  const EvaluationOutlineEdit.update(T this.value);

  /// The row deleted.
  const EvaluationOutlineEdit.delete() : value = null;

  /// The edited value; `null` when the row is deleted.
  final T? value;

  /// Whether the row is to be deleted.
  bool get isDelete => value == null;

  @override
  String toString() => 'EvaluationOutlineEdit(value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationOutlineEdit<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
