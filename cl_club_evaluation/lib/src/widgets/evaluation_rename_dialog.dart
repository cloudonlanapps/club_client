import 'package:cl_club_forms/cl_club_forms.dart'
    show RenameForm, RenameFormFields, RenameFormState;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';

/// Asks for one name — a template's — in an [EvaluationRenameDialog],
/// seeded with [initial], and writes it with [onSave], which resolves to
/// `null` once saved or to the refusal to show under the field (e.g. a name
/// already taken), keeping the dialog open. Resolves to the saved name, or
/// `null` when cancelled or unchanged (no write).
Future<String?> showEvaluationRenameDialog(
  BuildContext context, {
  required String title,
  required String label,
  required Future<String?> Function(String name) onSave,
  String? initial,
  String? Function(String)? validator,
}) {
  return showShadDialog<String>(
    context: context,
    builder: (_) => EvaluationRenameDialog(
      title: title,
      label: label,
      onSave: onSave,
      initial: initial,
      validator: validator,
    ),
  );
}

/// The dialog of [showEvaluationRenameDialog]: the cl_club_forms
/// `RenameForm` with Cancel and Save. It stays open while [onSave] runs,
/// with the form off and Save, Cancel and Enter doing nothing, and closes
/// only once the name is saved.
class EvaluationRenameDialog extends StatefulWidget {
  const EvaluationRenameDialog({
    required this.title,
    required this.label,
    required this.onSave,
    this.initial,
    this.validator,
    super.key,
  });

  /// The dialog's title.
  final String title;

  /// The field's label.
  final String label;

  /// Writes the name: `null` once saved, else the refusal to show under
  /// the field.
  final Future<String?> Function(String name) onSave;

  /// The name the field starts with.
  final String? initial;

  /// The field's validator; the form's own when null.
  final String? Function(String)? validator;

  @override
  State<EvaluationRenameDialog> createState() => EvaluationRenameDialogState();
}

/// State of [EvaluationRenameDialog].
class EvaluationRenameDialogState extends State<EvaluationRenameDialog> {
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
    if (value == widget.initial) {
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
    return ShadDialog(
      title: Text(widget.title),
      actions: [
        ShadButton.outline(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(EvaluationViewStrings.cancel),
        ),
        ShadButton(
          onPressed: isSaving ? null : save,
          child: const Text(EvaluationViewStrings.save),
        ),
      ],
      child: RenameForm(
        key: formKey,
        initialValue: widget.initial ?? '',
        label: widget.label,
        validator: widget.validator,
        enabled: !isSaving,
        onSubmitted: save,
      ),
    );
  }
}
