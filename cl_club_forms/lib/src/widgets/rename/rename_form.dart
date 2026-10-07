import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'rename_form_fields.dart';
import 'rename_form_validators.dart';

/// Pure-UI single-text-field form — the reusable body of any "rename" /
/// single-value edit affordance (group name, venue name, …).
///
/// The form owns no dialog or buttons: the host embeds it (typically inside
/// a `ShadDialog`) and drives it through a `GlobalKey<RenameFormState>` —
/// `validate()` from its Save action, `showErrors()` with what the server
/// refuses, e.g. a name already taken ([FormContract]). [onSubmitted] fires
/// when the user presses enter, so the host can route it to the same Save
/// path.
class RenameForm extends StatefulWidget {
  const RenameForm({
    required this.initialValue,
    required this.label,
    this.placeholder,
    this.validator,
    this.onSubmitted,
    this.enabled = true,
    super.key,
  });

  /// The text the field starts with.
  final String initialValue;

  /// The field's label; also names the field in the default validator's
  /// message.
  final String label;

  /// Hint shown in the empty field.
  final String? placeholder;

  /// Field validator. Defaults to [RenameFormValidators.required] against
  /// [label].
  final String? Function(String)? validator;

  /// Invoked when the user submits the field (enter key).
  final VoidCallback? onSubmitted;

  /// Whether the field responds; the host turns it off while it saves.
  final bool enabled;

  @override
  State<RenameForm> createState() => RenameFormState();
}

/// State of [RenameForm]. Its values are `{valueId: String}`, trimmed.
class RenameFormState extends State<RenameForm> with FormContract<RenameForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    RenameFormFields.valueId:
        (values[RenameFormFields.valueId] as String?)?.trim() ?? '',
  };

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.placeholder;
    return ShadForm(
      key: formKey,
      initialValue: {RenameFormFields.valueId: widget.initialValue},
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: widget.label,
            required: true,
            field: ShadInputFormField(
              id: RenameFormFields.valueId,
              enabled: widget.enabled,
              placeholder: placeholder == null ? null : Text(placeholder),
              keyboardType: TextInputType.name,
              autocorrect: false,
              enableSuggestions: false,
              validator:
                  widget.validator ??
                  (value) => RenameFormValidators.required(
                    value,
                    label: widget.label,
                  ),
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
