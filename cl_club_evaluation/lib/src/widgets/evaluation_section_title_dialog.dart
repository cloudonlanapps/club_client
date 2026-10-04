import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ConfirmDialog, EvaluationOutlineEdit, RenameForm, RenameFormState;

import '../constants/evaluation_view_strings.dart';

/// Asks for a section's title in a dialog hosting the ui_lib `RenameForm`
/// (`null` [title] for a new section). Resolves to the trimmed title, to a
/// delete — offered for an existing section, asked first; its items stay,
/// outside any section — or to `null` when cancelled or unchanged.
Future<EvaluationOutlineEdit<String>?> showEvaluationSectionTitleDialog(
  BuildContext context,
  String? title,
) {
  final formKey = GlobalKey<RenameFormState>();
  void save(BuildContext dialogContext) {
    final value = formKey.currentState?.validate();
    if (value == null) return;
    Navigator.of(
      dialogContext,
    ).pop(value == title ? null : EvaluationOutlineEdit.update(value));
  }

  Future<void> delete(BuildContext dialogContext) async {
    final ok = await ConfirmDialog.show(
      dialogContext,
      title: EvaluationViewStrings.deleteSectionTitle,
      message: EvaluationViewStrings.deleteSectionMessage,
      confirmLabel: EvaluationViewStrings.delete,
      destructive: true,
    );
    if (ok && dialogContext.mounted) {
      Navigator.of(
        dialogContext,
      ).pop(const EvaluationOutlineEdit<String>.delete());
    }
  }

  return showShadDialog<EvaluationOutlineEdit<String>>(
    context: context,
    builder: (dialogContext) => ShadDialog(
      title: const Text(EvaluationViewStrings.sectionTitle),
      actions: [
        if (title != null)
          ShadButton.ghost(
            leading: const Icon(LucideIcons.trash2),
            onPressed: () => delete(dialogContext),
            child: const Text(EvaluationViewStrings.delete),
          ),
        ShadButton.outline(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(EvaluationViewStrings.cancel),
        ),
        ShadButton(
          onPressed: () => save(dialogContext),
          child: const Text(EvaluationViewStrings.save),
        ),
      ],
      child: RenameForm(
        key: formKey,
        initialValue: title ?? '',
        label: EvaluationViewStrings.sectionTitle,
        onSubmitted: () => save(dialogContext),
      ),
    ),
  );
}
