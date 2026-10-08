import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'account_form_validators.dart';
import 'login_form_fields.dart';

/// Pure-UI username and password form (no SDK / no Riverpod).
///
/// The form owns no title, buttons or links: the host drives it through a
/// `GlobalKey<LoginFormState>`, calling `validate()` from its Sign in action
/// ([FormContract]). Enter in the password field calls [onSubmitted].
class LoginForm extends StatefulWidget {
  const LoginForm({this.enabled = true, this.onSubmitted, super.key});

  /// Whether the fields respond; the host turns it off while it signs in.
  final bool enabled;

  /// Enter in the password field; the host points it at its Sign in action.
  final VoidCallback? onSubmitted;

  @override
  State<LoginForm> createState() => LoginFormState();
}

/// State of [LoginForm]. Its values are
/// `{usernameId: String, passwordId: String}`, the username trimmed.
class LoginFormState extends State<LoginForm> with FormContract<LoginForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    LoginFormFields.usernameId:
        (values[LoginFormFields.usernameId] as String?)?.trim() ?? '',
    LoginFormFields.passwordId:
        values[LoginFormFields.passwordId] as String? ?? '',
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: const {
        LoginFormFields.usernameId: '',
        LoginFormFields.passwordId: '',
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Username',
            required: true,
            field: ShadInputFormField(
              id: LoginFormFields.usernameId,
              placeholder: const Text('your-username'),
              autofocus: true,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              enabled: widget.enabled,
              validator: AccountFormValidators.username,
            ),
          ),
          LabeledFormRow(
            label: 'Password',
            required: true,
            field: ShadInputFormField(
              id: LoginFormFields.passwordId,
              placeholder: const Text('••••••••'),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              enabled: widget.enabled,
              validator: AccountFormValidators.password,
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
