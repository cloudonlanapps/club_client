import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_kind.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../models/evaluation_layout_callbacks.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../../../models/evaluation_layout_position.dart';
import '../../../utils/evaluation_layout_ops.dart';
import 'evaluation_add_bar.dart';
import 'evaluation_outline_rows.dart';

/// The outline of a template's items and sections (SDK-free, no Riverpod).
///
/// Controlled: shows [layout] and reports every change as a whole new layout
/// through [onLayoutChanged]. A **Sort** checkbox reveals up / down arrows on
/// each row (no drag and drop); the "+" bar at the end adds a question of a
/// kind, an info text, a section or (with [onPickExisting]) an existing
/// question, and a section's own "+" adds into it. Tapping a row edits it;
/// a row is deleted from its dialog, not from the outline.
///
/// Opens no dialog itself: adding or tapping an item awaits [onEditItem]
/// (with a new item of the kind, id `null`, when adding), and adding or
/// tapping a section awaits [onEditSectionTitle]; the host shows its dialog
/// and resolves to an `EvaluationOutlineEdit` — the edited value or a
/// delete — or `null` to cancel.
class EvaluationLayoutEditor extends StatefulWidget {
  /// Edits [layout].
  const EvaluationLayoutEditor({
    required this.layout,
    required this.onLayoutChanged,
    required this.onEditItem,
    required this.onEditSectionTitle,
    this.onPickExisting,
    this.onViewItem,
    this.readOnly = false,
    super.key,
  });

  /// The items and sections, in order.
  final List<EvaluationLayoutEntry> layout;

  /// Called with the new layout after every change.
  final ValueChanged<List<EvaluationLayoutEntry>> onLayoutChanged;

  /// Edits an item through the host's dialog.
  final EvaluationEditItem onEditItem;

  /// Edits a section's title through the host's dialog.
  final EvaluationEditSectionTitle onEditSectionTitle;

  /// Picks an existing question to copy; `null` hides the option.
  final EvaluationPickExisting? onPickExisting;

  /// Shows an item of a read-only outline; `null` leaves its rows inert.
  final EvaluationViewItem? onViewItem;

  /// Hides Sort and add (a frozen template). Tapping an item then calls
  /// [onViewItem], never [onEditItem]; a section's row is inert.
  final bool readOnly;

  @override
  State<EvaluationLayoutEditor> createState() => EvaluationLayoutEditorState();
}

/// State of [EvaluationLayoutEditor]: whether the outline is being sorted.
class EvaluationLayoutEditorState extends State<EvaluationLayoutEditor> {
  /// Whether the reorder arrows show.
  bool sorting = false;

  /// Reports [next] unless read-only or gone.
  void emit(List<EvaluationLayoutEntry>? next) {
    if (next == null || widget.readOnly || !mounted) return;
    widget.onLayoutChanged(next);
  }

  /// Edits the item at [pos] in place, or deletes it; read-only, shows it.
  Future<void> editItem(EvaluationLayoutPosition pos) async {
    final item = EvaluationLayoutOps.itemAt(widget.layout, pos);
    if (item == null) return;
    if (widget.readOnly) return widget.onViewItem?.call(item);
    final edit = await widget.onEditItem(item);
    if (edit == null) return;
    final edited = edit.value;
    emit(
      edited == null
          ? EvaluationLayoutOps.remove(widget.layout, pos)
          : EvaluationLayoutOps.replaceItem(widget.layout, pos, edited),
    );
  }

  /// Retitles the section at index [section], or deletes it (its items
  /// stay, outside any section).
  Future<void> editSection(int section) async {
    final edit = await widget.onEditSectionTitle(
      widget.layout[section].sectionTitle,
    );
    if (edit == null) return;
    final title = edit.value;
    if (title == null) {
      emit(
        EvaluationLayoutOps.remove(
          widget.layout,
          EvaluationLayoutPosition(entry: section),
        ),
      );
    } else if (title.trim().isNotEmpty) {
      emit(EvaluationLayoutOps.renameSection(widget.layout, section, title));
    }
  }

  /// Adds a new item of [kind], at the end or into [section].
  Future<void> addItem(EvaluationItemKind kind, {int? section}) async {
    final edit = await widget.onEditItem(EvaluationItemValue.newOfKind(kind));
    final item = edit?.value;
    if (item == null) return;
    emit(EvaluationLayoutOps.appendItem(widget.layout, item, section: section));
  }

  /// Adds a copy of an existing question, at the end or into [section].
  Future<void> addExisting({int? section}) async {
    final item = await widget.onPickExisting?.call();
    if (item == null) return;
    emit(EvaluationLayoutOps.appendItem(widget.layout, item, section: section));
  }

  /// Adds a new, empty section at the end.
  Future<void> addSection() async {
    final title = (await widget.onEditSectionTitle(null))?.value;
    if (title == null || title.trim().isEmpty) return;
    emit(EvaluationLayoutOps.appendSection(widget.layout, title.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final readOnly = widget.readOnly;
    final existing = widget.onPickExisting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.smallGap,
      children: [
        if (!readOnly && layout.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ShadCheckbox(
              value: sorting,
              label: Text(
                EvaluationStrings.sort,
                style: ShadTheme.of(context).textTheme.small,
              ),
              onChanged: (on) => setState(() => sorting = on),
            ),
          ),
        EvaluationOutlineRows(
          layout: layout,
          sorting: sorting && !readOnly,
          readOnly: readOnly,
          onEditItem: readOnly && widget.onViewItem == null ? null : editItem,
          onEditSection: readOnly ? null : editSection,
          onMove: (pos, delta) =>
              emit(EvaluationLayoutOps.move(widget.layout, pos, delta)),
          onAddToSection: (kind, section) => addItem(kind, section: section),
          onAddExistingToSection: existing == null
              ? null
              : (section) => addExisting(section: section),
        ),
        if (!readOnly)
          EvaluationAddBar(
            onAddItem: addItem,
            onAddSection: addSection,
            onAddExisting: existing == null ? null : addExisting,
          ),
      ],
    );
  }
}
