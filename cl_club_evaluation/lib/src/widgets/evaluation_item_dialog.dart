import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ConfirmDialog,
        EvaluationItemForm,
        EvaluationItemFormState,
        EvaluationItemFormValues,
        EvaluationItemValue,
        EvaluationOutlineEdit,
        EvaluationSpacing;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_item_adapter.dart';

/// Edits [item] in an [EvaluationItemDialog]; resolves to the edited item
/// or a delete, or `null` when cancelled. With [readOnly] the item is only
/// shown, and the dialog resolves to `null`.
Future<EvaluationOutlineEdit<EvaluationItemValue>?> showEvaluationItemDialog(
  BuildContext context,
  EvaluationItemValue item, {
  bool readOnly = false,
}) => showShadDialog<EvaluationOutlineEdit<EvaluationItemValue>>(
  context: context,
  // Tapping outside must not drop the edits; Escape cancels in the dialog.
  barrierDismissible: false,
  builder: (_) => EvaluationItemDialog(item: item, readOnly: readOnly),
);

/// A dialog hosting the ui_lib `EvaluationItemForm` (form rule 17).
///
/// **Save** (or **Add** for a new item) validates and closes with the
/// edited item, which keeps [item]'s id and origin; a copy keeps its
/// origin's choice values ([EvaluationItemAdapter.keepOrigin]). **Delete**
/// — offered for an item that exists — asks first. Cancel, Escape and back
/// ask before dropping changes. Tapping outside does nothing. [readOnly]
/// shows the item with its fields disabled and **Close** only.
class EvaluationItemDialog extends StatefulWidget {
  /// Edits [item].
  const EvaluationItemDialog({
    required this.item,
    this.readOnly = false,
    super.key,
  });

  /// The item as it is now, or a new item of its kind.
  final EvaluationItemValue item;

  /// Whether the item is only shown.
  final bool readOnly;

  /// Whether [item] is being added: it has neither id nor text yet.
  bool get isNew => item.id == null && item.text.isEmpty;

  @override
  State<EvaluationItemDialog> createState() => EvaluationItemDialogState();
}

/// State of [EvaluationItemDialog]: the form, and whether a prompt is open.
class EvaluationItemDialogState extends State<EvaluationItemDialog> {
  /// The item form.
  final GlobalKey<EvaluationItemFormState> formKey =
      GlobalKey<EvaluationItemFormState>();

  /// Whether a discard or delete prompt is showing.
  bool prompting = false;

  /// Closes the dialog with [result].
  void close([EvaluationOutlineEdit<EvaluationItemValue>? result]) =>
      Navigator.of(context).pop(result);

  /// Asks [title] / [message] with [confirmLabel]; `true` when confirmed.
  Future<bool> confirm({
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = EvaluationViewStrings.cancel,
  }) async {
    if (prompting) return false;
    prompting = true;
    final ok = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: true,
    );
    prompting = false;
    return ok && mounted;
  }

  /// Leaves without changes, asking first when the form has changed.
  Future<void> cancel() async {
    if (prompting) return;
    final dirty = !widget.readOnly && (formKey.currentState?.isDirty ?? false);
    if (dirty &&
        !await confirm(
          title: EvaluationViewStrings.discardItemTitle,
          message: EvaluationViewStrings.discardItemMessage,
          confirmLabel: EvaluationViewStrings.discard,
          cancelLabel: EvaluationViewStrings.keepEditing,
        )) {
      return;
    }
    if (mounted) close();
  }

  /// Validates the form and closes with the edited item.
  void save() {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    final item = widget.item;
    final edited = EvaluationItemFormValues.toItem(values, kind: item.kind);
    close(
      EvaluationOutlineEdit.update(
        EvaluationItemAdapter.keepOrigin(item, edited),
      ),
    );
  }

  /// Closes with a delete, once confirmed.
  Future<void> delete() async {
    if (await confirm(
      title: EvaluationViewStrings.deleteItemTitle,
      message: EvaluationViewStrings.deleteItemMessage,
      confirmLabel: EvaluationViewStrings.delete,
    )) {
      close(const EvaluationOutlineEdit.delete());
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final readOnly = widget.readOnly;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(cancel());
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              unawaited(cancel()),
        },
        child: Focus(
          autofocus: true,
          child: ShadDialog(
            title: Text(item.kind.label),
            // Its close icon would skip the discard prompt.
            closeIcon: const SizedBox.shrink(),
            constraints: const BoxConstraints(
              maxWidth: EvaluationSpacing.itemDialogWidth,
            ),
            actions: readOnly
                ? [
                    ShadButton.outline(
                      onPressed: close,
                      child: const Text(EvaluationViewStrings.close),
                    ),
                  ]
                : [
                    if (!widget.isNew)
                      ShadButton.ghost(
                        leading: const Icon(LucideIcons.trash2),
                        onPressed: delete,
                        child: const Text(EvaluationViewStrings.delete),
                      ),
                    ShadButton.outline(
                      onPressed: cancel,
                      child: const Text(EvaluationViewStrings.cancel),
                    ),
                    ShadButton(
                      onPressed: save,
                      child: Text(
                        widget.isNew
                            ? EvaluationViewStrings.add
                            : EvaluationViewStrings.save,
                      ),
                    ),
                  ],
            child: EvaluationItemForm(
              key: formKey,
              kind: item.kind,
              readOnly: readOnly,
              initialValues: EvaluationItemFormValues.fromItem(item),
            ),
          ),
        ),
      ),
    );
  }
}
