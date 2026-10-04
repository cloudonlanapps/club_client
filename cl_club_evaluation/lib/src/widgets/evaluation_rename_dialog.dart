import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show RenameForm, RenameFormState;

import '../constants/evaluation_view_strings.dart';

/// Asks for one name — a template's — in a dialog hosting the ui_lib
/// `RenameForm`, seeded with [initial], and writes it with [onSave], which
/// resolves to `null` once saved or to the refusal to show under the field
/// (e.g. a name already taken), keeping the dialog open. Resolves to the
/// saved name, or `null` when cancelled or unchanged (no write).
Future<String?> showEvaluationRenameDialog(
  BuildContext context, {
  required String title,
  required String label,
  required Future<String?> Function(String name) onSave,
  String? initial,
  String? Function(String)? validator,
}) {
  final formKey = GlobalKey<RenameFormState>();
  Future<void> save(BuildContext dialogContext) async {
    final value = formKey.currentState?.validate();
    if (value == null) return;
    if (value == initial) {
      Navigator.of(dialogContext).pop();
      return;
    }
    final refusal = await onSave(value);
    if (!dialogContext.mounted) return;
    if (refusal == null) {
      Navigator.of(dialogContext).pop(value);
    } else {
      formKey.currentState?.setError(refusal);
    }
  }

  return showShadDialog<String>(
    context: context,
    builder: (dialogContext) => ShadDialog(
      title: Text(title),
      actions: [
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
        initialValue: initial ?? '',
        label: label,
        validator: validator,
        onSubmitted: () => save(dialogContext),
      ),
    ),
  );
}
