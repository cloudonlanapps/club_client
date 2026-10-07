import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pure-UI single-text-field form — the reusable body of any "rename" /
/// single-value edit affordance (group name, venue name, …).
///
/// Host-agnostic: it owns no Scaffold, dialog, or buttons. A caller embeds it
/// (typically inside a `ShadDialog`) and drives it through a
/// `GlobalKey<RenameFormState>`: call [RenameFormState.validate] from the Save
/// action to validate and read the trimmed value. [onSubmitted] fires when the
/// user presses enter, so the host can route it to the same Save path.
class RenameForm extends StatefulWidget {
  const RenameForm({
    required this.initialValue,
    required this.label,
    super.key,
    this.placeholder,
    this.validator,
    this.onSubmitted,
  });

  final String initialValue;
  final String label;
  final String? placeholder;

  /// Field validator. Defaults to a non-empty check against [label].
  final String? Function(String)? validator;

  /// Invoked when the user submits the field (enter key).
  final VoidCallback? onSubmitted;

  static const String fieldId = 'value';

  @override
  State<RenameForm> createState() => RenameFormState();
}

class RenameFormState extends State<RenameForm> {
  final formKey = GlobalKey<ShadFormState>();

  String? _defaultValidator(String value) {
    if (value.trim().isEmpty) return '${widget.label} is required';
    return null;
  }

  /// Validates the field. Returns the trimmed value when valid, else `null`.
  String? validate() {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return null;
    form.save();
    return (form.value[RenameForm.fieldId] as String?)?.trim() ?? '';
  }

  /// Shows [message] under the field — the host's server refusal, e.g. a
  /// name already taken. The next [validate] clears it.
  void setError(String message) =>
      formKey.currentState?.fields[RenameForm.fieldId]?.setError(message);

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: {RenameForm.fieldId: widget.initialValue},
      child: ShadInputFormField(
        id: RenameForm.fieldId,
        label: Text(widget.label),
        placeholder: widget.placeholder == null
            ? null
            : Text(widget.placeholder!),
        keyboardType: TextInputType.name,
        autocorrect: false,
        enableSuggestions: false,
        validator: widget.validator ?? _defaultValidator,
        onSubmitted: (_) => widget.onSubmitted?.call(),
      ),
    );
  }
}
