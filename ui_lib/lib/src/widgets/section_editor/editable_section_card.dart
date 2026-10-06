import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'section_edit_button.dart';
import 'section_editor_actions.dart';

/// A titled [ShadCard] section that edits **in place** — the canonical
/// section-wise editor chrome.
///
/// Read mode shows the section title (with an optional leading icon) plus a
/// [SectionEditButton] when [canEdit] is true, above the read-only [read]
/// content. Tapping the pencil (or the empty hint) flips the same card into
/// edit mode, which renders the form returned by [editBuilder] inline with
/// `Cancel` / `Save` actions — no dialog or popover.
///
/// The card owns only UI concerns: the read/edit toggle, validation gating,
/// no-op detection ([isDirty]) and the in-flight saving state. It is
/// SDK-free; the host supplies:
///
/// * [onValidate] — reads the form's `GlobalKey` state and returns the partial
///   value map (or `null` when invalid, which keeps the card in edit mode and
///   lets the form surface its own field errors);
/// * [onSave] — performs the partial update (SDK call + toast + provider
///   invalidation) and returns `true` on success so the card knows to leave
///   edit mode (and stays open on failure so the user can retry).
///
/// `T` is the form's value type (`Map<String, dynamic>` for the multi-field
/// section forms, but anything the form's `validate()` returns).
class EditableSectionCard<T> extends StatefulWidget {
  const EditableSectionCard({
    required this.title,
    required this.read,
    required this.editBuilder,
    required this.onValidate,
    required this.onSave,
    this.canEdit = false,
    this.leadingIcon,
    this.isEmpty = false,
    this.emptyHint,
    this.isDirty,
    this.onBeforeEdit,
    this.editMaxWidth,
    this.onReset,
    this.canReset,
    super.key,
  });

  /// Section heading shown in both modes.
  final String title;

  /// Optional leading icon shown before the title.
  final IconData? leadingIcon;

  /// Read-only content shown when not editing (typically a column of rows).
  final Widget read;

  /// Builds the inline edit form. Invoked only while editing, so the form's
  /// `GlobalKey` (held by the host) attaches only in edit mode.
  final Widget Function() editBuilder;

  /// Reads the form's state and returns the partial value, or `null` when the
  /// form is invalid.
  final T? Function() onValidate;

  /// Applies the partial update. Returns `true` on success (card leaves edit
  /// mode), `false` on failure (card stays in edit mode for retry).
  final Future<bool> Function(T value) onSave;

  /// Whether the viewer may edit this section. When false, no edit affordance
  /// is shown and the section is read-only.
  final bool canEdit;

  /// Whether [read] currently has no content. When true, [emptyHint] replaces
  /// it and (if [canEdit]) tapping the hint enters edit mode.
  final bool isEmpty;

  /// Hint shown in place of [read] when [isEmpty] is true.
  final String? emptyHint;

  /// Optional dirtiness hook reading the form's state. When provided and it
  /// returns false (nothing changed), Save is a no-op: the card skips
  /// validation and [onSave] and simply leaves edit mode.
  final bool Function()? isDirty;

  /// Optional async gate run when the viewer taps the edit affordance, before
  /// the card enters edit mode. Return `true` to proceed into the editor,
  /// `false` to stay in read mode (e.g. the user declined a confirmation).
  /// Re-taps are ignored while it runs. Use it for a pre-edit check +
  /// confirmation (e.g. "this reschedule will clear N occurrence overrides —
  /// continue?").
  final Future<bool> Function()? onBeforeEdit;

  /// Optional max width for the inline edit form (left-aligned). Keeps wide
  /// desktop layouts from stretching the form full width.
  final double? editMaxWidth;

  /// Optional reset action, shown beside Cancel and Save in edit mode while
  /// [canReset] returns true. Empties the host's form; nothing is stored
  /// until Save.
  final VoidCallback? onReset;

  /// Whether the form holds a value to reset. The host rebuilds the card
  /// when the answer may have changed.
  final bool Function()? canReset;

  @override
  State<EditableSectionCard<T>> createState() => _EditableSectionCardState<T>();
}

class _EditableSectionCardState<T> extends State<EditableSectionCard<T>> {
  bool _editing = false;
  bool _saving = false;
  bool _preparing = false;

  Future<void> _enterEdit() async {
    if (_preparing) return;
    final gate = widget.onBeforeEdit;
    if (gate != null) {
      setState(() => _preparing = true);
      bool proceed;
      try {
        proceed = await gate();
      } finally {
        if (mounted) setState(() => _preparing = false);
      }
      if (!proceed || !mounted) return;
    }
    setState(() => _editing = true);
  }

  void _cancel() => setState(() => _editing = false);

  Future<void> _save() async {
    // Nothing changed → an unmodified Save just closes the editor.
    if (widget.isDirty != null && !widget.isDirty!()) {
      setState(() => _editing = false);
      return;
    }
    final value = widget.onValidate();
    if (value == null) return; // invalid — form shows its own errors
    setState(() => _saving = true);
    final ok = await widget.onSave(value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // An empty section is hidden from a read-only viewer entirely — there's
    // nothing to show and nothing they can add. An editor still sees it (with
    // the tap-to-add hint) so they can introduce the section.
    if (widget.isEmpty && !widget.canEdit && !_editing) {
      return const SizedBox.shrink();
    }
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(
                  widget.leadingIcon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
              ],
              Text(widget.title, style: theme.textTheme.h4),
              const Spacer(),
              if (widget.canEdit && !_editing)
                SectionEditButton(onTap: _enterEdit),
            ],
          ),
          const SizedBox(height: 16),
          if (_editing) _buildEdit(context) else _buildRead(context),
        ],
      ),
    );
  }

  Widget _buildRead(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (!widget.isEmpty) return widget.read;
    final hint = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        widget.emptyHint ?? '',
        style: theme.textTheme.muted,
      ),
    );
    if (!widget.canEdit) return hint;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enterEdit,
        child: hint,
      ),
    );
  }

  Widget _buildEdit(BuildContext context) {
    final form = widget.editMaxWidth == null
        ? widget.editBuilder()
        : Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.editMaxWidth!),
              child: widget.editBuilder(),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        form,
        const SizedBox(height: 16),
        SectionEditorActions(
          saving: _saving,
          onCancel: _cancel,
          onSave: _save,
          onReset: (widget.canReset?.call() ?? false) ? widget.onReset : null,
        ),
      ],
    );
  }
}
