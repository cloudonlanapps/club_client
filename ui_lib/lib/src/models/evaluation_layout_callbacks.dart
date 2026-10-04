import 'evaluation_item_value.dart';
import 'evaluation_outline_edit.dart';

/// Edits an item; resolves to the edited item or a delete, or `null` when
/// cancelled. An item being added (no id, no text) offers no delete.
typedef EvaluationEditItem =
    Future<EvaluationOutlineEdit<EvaluationItemValue>?> Function(
      EvaluationItemValue item,
    );

/// Edits a section's title (`null` for a new section); resolves to the
/// title or a delete, or `null` when cancelled. Deleting a section keeps its
/// items, outside any section.
typedef EvaluationEditSectionTitle =
    Future<EvaluationOutlineEdit<String>?> Function(String? title);

/// Shows an item without letting it change (a frozen template).
typedef EvaluationViewItem = Future<void> Function(EvaluationItemValue item);

/// Picks an existing question to copy; resolves to the copy, or `null`.
typedef EvaluationPickExisting = Future<EvaluationItemValue?> Function();
