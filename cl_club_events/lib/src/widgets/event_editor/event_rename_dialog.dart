import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormValidators, RenameForm, RenameFormFields, RenameFormState;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Hosts the shared [RenameForm] in a dialog. Resolves to the trimmed new
/// title, or `null` on Cancel / dismiss / no-op (title unchanged).
Future<String?> showEventRenameDialog(
  BuildContext context,
  String initialTitle,
) {
  final formKey = GlobalKey<RenameFormState>();
  return showShadDialog<String?>(
    context: context,
    builder: (dialogContext) {
      void save() {
        final value =
            formKey.currentState?.validate()?[RenameFormFields.valueId]
                as String?;
        if (value == null) return;
        Navigator.of(
          dialogContext,
        ).pop(value == initialTitle.trim() ? null : value);
      }

      return ShadDialog(
        title: const Text('Rename event'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ShadButton(onPressed: save, child: const Text('Save')),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: RenameForm(
            key: formKey,
            initialValue: initialTitle,
            label: 'Event name',
            placeholder: 'e.g., Summer Skating Camp',
            validator: EventFormValidators.title,
            onSubmitted: save,
          ),
        ),
      );
    },
  );
}
