import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// The password and its confirmation, shared by the forms that create an
/// account. The embedding form checks that the two match
/// (`UserFormValidators.passwordsMatch`).
class UserPasswordFields extends StatelessWidget {
  const UserPasswordFields({this.enabled = true, super.key});

  /// Whether the fields respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormBody(
      children: [
        LabeledFormRow(
          label: UserFormStrings.password,
          required: true,
          field: ShadInputFormField(
            id: UserFormFields.passwordId,
            placeholder: const Text(UserFormStrings.passwordPlaceholder),
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            obscureText: true,
            enabled: enabled,
            validator: UserFormValidators.password,
          ),
        ),
        LabeledFormRow(
          label: UserFormStrings.confirmPassword,
          required: true,
          field: ShadInputFormField(
            id: UserFormFields.confirmPasswordId,
            placeholder: const Text(
              UserFormStrings.confirmPasswordPlaceholder,
            ),
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            obscureText: true,
            enabled: enabled,
            validator: UserFormValidators.confirmPassword,
          ),
        ),
      ],
    );
  }
}
