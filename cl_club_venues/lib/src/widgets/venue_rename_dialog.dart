import 'package:cl_club_forms/cl_club_forms.dart'
    show RenameForm, RenameFormFields, RenameFormState, VenueFormValidators;
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

/// Asks for a venue's new name in a [VenueRenameDialog], seeded with
/// [initialName], and writes it with [onSave], which resolves to `null` once
/// saved or to the refusal to show under the field, keeping the dialog open.
/// Resolves to the saved name, trimmed, or `null` on Cancel / dismiss /
/// no-op (name unchanged, no write).
Future<String?> showVenueRenameDialog(
  BuildContext context,
  String initialName, {
  required Future<String?> Function(String name) onSave,
}) {
  return showShadDialog<String?>(
    context: context,
    builder: (_) => VenueRenameDialog(initialName: initialName, onSave: onSave),
  );
}

/// The dialog of [showVenueRenameDialog]: the shared [RenameForm] with
/// Cancel and Save. It stays open while [onSave] runs, with the form off and
/// Save, Cancel and Enter doing nothing, and closes only once the name is
/// saved. It sits in a `PointerInterceptor`, so the map under it takes none
/// of its clicks.
class VenueRenameDialog extends StatefulWidget {
  const VenueRenameDialog({
    required this.initialName,
    required this.onSave,
    super.key,
  });

  /// The name the field starts with.
  final String initialName;

  /// Writes the name: `null` once saved, else the refusal to show under
  /// the field.
  final Future<String?> Function(String name) onSave;

  @override
  State<VenueRenameDialog> createState() => VenueRenameDialogState();
}

/// State of [VenueRenameDialog].
class VenueRenameDialogState extends State<VenueRenameDialog> {
  /// Drives the hosted form.
  final GlobalKey<RenameFormState> formKey = GlobalKey<RenameFormState>();

  /// Whether a save is in flight.
  bool isSaving = false;

  /// Saves the typed name, once: closes when it is unchanged or saved, and
  /// puts a refusal on the field.
  Future<void> save() async {
    if (isSaving) return;
    final value =
        formKey.currentState?.validate()?[RenameFormFields.valueId] as String?;
    if (value == null) return;
    final navigator = Navigator.of(context);
    if (value == widget.initialName.trim()) {
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
    return PointerInterceptor(
      child: SavingDialogScope(
        saving: isSaving,
        child: ShadDialog(
          closeIcon: SavingDialogCloseIcon(saving: isSaving),
          title: const Text('Rename venue'),
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
              initialValue: widget.initialName,
              label: 'Venue name',
              placeholder: 'e.g., Main Arena',
              validator: VenueFormValidators.name,
              enabled: !isSaving,
              onSubmitted: save,
            ),
          ),
        ),
      ),
    );
  }
}
