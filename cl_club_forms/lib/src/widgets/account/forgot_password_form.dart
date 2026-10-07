import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import '../user_form/user_form_validators.dart';
import 'forgot_password_form_fields.dart';

/// Pure-UI "forgot password" form (no SDK / no Riverpod): the member's
/// email.
///
/// The server never reveals whether an email matches a member, so the form
/// only gathers a well-formed address.
///
/// The form owns no title, buttons or links: the host drives it through a
/// `GlobalKey<ForgotPasswordFormState>`, calling `validate()` from its Send
/// action ([FormContract]). Enter in the field calls [onSubmitted].
class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({this.enabled = true, this.onSubmitted, super.key});

  /// Whether the field responds; the host turns it off while it sends.
  final bool enabled;

  /// Called when the member presses Enter in the field; the host points it
  /// at its Send action.
  final VoidCallback? onSubmitted;

  @override
  State<ForgotPasswordForm> createState() => ForgotPasswordFormState();
}

/// State of [ForgotPasswordForm]. Its value is `{emailId: String}`, trimmed.
class ForgotPasswordFormState extends State<ForgotPasswordForm>
    with FormContract<ForgotPasswordForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ForgotPasswordFormFields.emailId:
        (values[ForgotPasswordFormFields.emailId] as String?)?.trim() ?? '',
  };

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: const {ForgotPasswordFormFields.emailId: ''},
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Email',
            required: true,
            field: ShadInputFormField(
              id: ForgotPasswordFormFields.emailId,
              placeholder: const Text('you@example.com'),
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              enabled: widget.enabled,
              validator: UserFormValidators.email,
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ],
      ),
    );
  }
}
