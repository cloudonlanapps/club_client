import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormValidators, RenameForm, RenameFormFields, RenameFormState;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

/// Asks for an event's new title in an [EventRenameDialog], seeded with
/// [initialTitle], and writes it with [onSave], which resolves to `null` once
/// saved or to the refusal to show under the field, keeping the dialog open.
/// Resolves to the saved title, trimmed, or `null` on Cancel / dismiss /
/// no-op (title unchanged, no write).
Future<String?> showEventRenameDialog(
  BuildContext context,
  String initialTitle, {
  required Future<String?> Function(String title) onSave,
}) {
  return showShadDialog<String?>(
    context: context,
    builder: (_) =>
        EventRenameDialog(initialTitle: initialTitle, onSave: onSave),
  );
}

/// The dialog of [showEventRenameDialog]: the shared [RenameForm] with
/// Cancel and Save. It stays open while [onSave] runs, with the form off and
/// Save, Cancel and Enter doing nothing, and closes only once the title is
/// saved.
class EventRenameDialog extends StatefulWidget {
  const EventRenameDialog({
    required this.initialTitle,
    required this.onSave,
    super.key,
  });

  /// The title the field starts with.
  final String initialTitle;

  /// Writes the title: `null` once saved, else the refusal to show under
  /// the field.
  final Future<String?> Function(String title) onSave;

  @override
  State<EventRenameDialog> createState() => EventRenameDialogState();
}

/// State of [EventRenameDialog].
class EventRenameDialogState extends State<EventRenameDialog> {
  /// Drives the hosted form.
  final GlobalKey<RenameFormState> formKey = GlobalKey<RenameFormState>();

  /// Whether a save is in flight.
  bool isSaving = false;

  /// Saves the typed title, once: closes when it is unchanged or saved, and
  /// puts a refusal on the field.
  Future<void> save() async {
    if (isSaving) return;
    final value =
        formKey.currentState?.validate()?[RenameFormFields.valueId] as String?;
    if (value == null) return;
    final navigator = Navigator.of(context);
    if (value == widget.initialTitle.trim()) {
      navigator.pop();
      return;
    }
    setState(() => isSaving = true);
    final refusal = await widget.onSave(value);
    if (!mounted) return;
    if (refusal == null) {
      navigator.pop(value);
      return;
    }
    setState(() => isSaving = false);
    formKey.currentState?.showErrors(
      fieldErrors: {RenameFormFields.valueId: refusal},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SavingDialogScope(
      saving: isSaving,
      child: ShadDialog(
        closeIcon: SavingDialogCloseIcon(saving: isSaving),
        title: const Text('Rename event'),
        actions: [
          ShadButton.outline(
            onPressed: isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: isSaving ? null : save,
            child: const Text('Save'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: RenameForm(
            key: formKey,
            initialValue: widget.initialTitle,
            label: 'Event name',
            placeholder: 'e.g., Summer Skating Camp',
            validator: EventFormValidators.title,
            enabled: !isSaving,
            onSubmitted: save,
          ),
        ),
      ),
    );
  }
}
