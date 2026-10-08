import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../theme/text_theme_extensions.dart';

/// The action row under an inline section editor: an optional Clear, then
/// Cancel and Save. Used by `EditableSectionCard`; every action is disabled
/// while [saving], and Save then reads [savingLabel].
class SectionEditorActions extends StatelessWidget {
  const SectionEditorActions({
    required this.saving,
    required this.onCancel,
    required this.onSave,
    this.onClear,
    super.key,
  });

  /// Whether a save is in flight.
  final bool saving;

  /// Leaves edit mode without saving.
  final VoidCallback onCancel;

  /// Validates and saves the section.
  final VoidCallback onSave;

  /// Empties the form. `null` shows no Clear.
  final VoidCallback? onClear;

  static const String clearLabel = 'Clear';
  static const String cancelLabel = 'Cancel';
  static const String saveLabel = 'Save';

  /// What Save reads while the save is in flight.
  static const String savingLabel = 'Saving…';

  /// Gap between two actions.
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      spacing: gap,
      children: [
        if (onClear != null)
          ShadButton.outline(
            enabled: !saving,
            onPressed: saving ? null : onClear,
            child: const Text(clearLabel),
          ),
        ShadButton.outline(
          enabled: !saving,
          onPressed: saving ? null : onCancel,
          child: const Text(cancelLabel),
        ),
        ShadButton(
          enabled: !saving,
          onPressed: saving ? null : onSave,
          child: Text(
            saving ? savingLabel : saveLabel,
            style: theme.textTheme.buttonLabel,
          ),
        ),
      ],
    );
  }
}
