import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'user_form_fields.dart';
import 'user_form_strings.dart';

/// The tick that gives a created account the default password, with the
/// action that shows what that password is.
class UserDefaultPasswordField extends StatelessWidget {
  const UserDefaultPasswordField({
    required this.value,
    required this.onChanged,
    this.onShow,
    this.enabled = true,
    super.key,
  });

  /// Whether the default password is used.
  final bool value;

  /// Called when the tick changes.
  final ValueChanged<bool> onChanged;

  /// Shows the default password; null hides the action.
  final VoidCallback? onShow;

  /// Whether the tick and the action respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShadCheckboxFormField(
            id: UserFormFields.useDefaultPasswordId,
            initialValue: value,
            inputLabel: const Text(UserFormStrings.useDefaultPassword),
            enabled: enabled,
            onChanged: onChanged,
          ),
        ),
        if (value && onShow != null)
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: enabled ? onShow : null,
            child: const Text(UserFormStrings.showDefaultPassword),
          ),
      ],
    );
  }
}
