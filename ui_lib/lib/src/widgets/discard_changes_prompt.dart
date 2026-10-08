import 'package:flutter/widgets.dart';

import 'confirm_dialog.dart';

/// The one prompt shown before leaving a form that holds unsaved changes: a
/// [ConfirmDialog] with one wording, for every create view.
class DiscardChangesPrompt {
  const DiscardChangesPrompt._();

  /// The prompt's title.
  static const String title = 'Discard changes?';

  /// The prompt's message.
  static const String message = 'You have unsaved changes.';

  /// The action that leaves and drops the changes.
  static const String discardLabel = 'Discard';

  /// The action that stays on the form.
  static const String keepEditingLabel = 'Keep editing';

  /// Asks whether to drop the changes. Resolves to `true` when the user
  /// chose [discardLabel], and to `false` when they stayed or dismissed
  /// the prompt.
  static Future<bool> show(BuildContext context) => ConfirmDialog.show(
    context,
    title: title,
    message: message,
    confirmLabel: discardLabel,
    cancelLabel: keepEditingLabel,
    destructive: true,
  );
}
