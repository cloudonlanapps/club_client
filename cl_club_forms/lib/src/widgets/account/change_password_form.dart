import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'account_form_validators.dart';
import 'change_password_form_fields.dart';

/// Pure-UI "change password" form (no SDK / no Riverpod): the current
/// password, the new one and the new one again.
///
/// The form owns no title, buttons or card: the host drives it through a
/// `GlobalKey<ChangePasswordFormState>` — `validate()` from its Update
/// action, `showErrors()` when the server refuses the current password
/// ([FormContract]).
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({this.enabled = true, super.key});

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ChangePasswordForm> createState() => ChangePasswordFormState();
}

/// State of [ChangePasswordForm]. Its values are
/// `{currentId: String, nextId: String}`; the confirmation is checked and
/// left out.
class ChangePasswordFormState extends State<ChangePasswordForm>
    with FormContract<ChangePasswordForm> {
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      AccountFormValidators.newPasswordsMatch(
        values[ChangePasswordFormFields.nextId] as String?,
        values[ChangePasswordFormFields.confirmId] as String?,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ChangePasswordFormFields.currentId:
        values[ChangePasswordFormFields.currentId] as String? ?? '',
    ChangePasswordFormFields.nextId:
        values[ChangePasswordFormFields.nextId] as String? ?? '',
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: const {
        ChangePasswordFormFields.currentId: '',
        ChangePasswordFormFields.nextId: '',
        ChangePasswordFormFields.confirmId: '',
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Current password',
            required: true,
            field: ShadInputFormField(
              id: ChangePasswordFormFields.currentId,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              enabled: widget.enabled,
              validator: AccountFormValidators.currentPassword,
            ),
          ),
          LabeledFormRow(
            label: 'New password',
            required: true,
            field: ShadInputFormField(
              id: ChangePasswordFormFields.nextId,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              enabled: widget.enabled,
              validator: AccountFormValidators.newPassword,
            ),
          ),
          LabeledFormRow(
            label: 'Confirm new password',
            required: true,
            field: ShadInputFormField(
              id: ChangePasswordFormFields.confirmId,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              enabled: widget.enabled,
              validator: AccountFormValidators.confirmation,
            ),
          ),
        ],
      ),
    );
  }
}
