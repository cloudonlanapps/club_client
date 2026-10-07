import 'package:cl_club_forms/src/widgets/user_form/user_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pure-UI "forgot password" form (no SDK / no Riverpod).
///
/// Collects the member's email, validates it client-side, and calls [onSubmit]
/// with the trimmed address. The host owns the SDK call, the in-flight flag
/// ([isSubmitting]), and any confirmation / error messaging. [onBack] returns
/// to sign in.
///
/// The server never reveals whether an email matches a member, so this form
/// makes no attempt to verify existence — it only gathers a well-formed
/// address and hands it off.
class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({
    required this.onSubmit,
    required this.onBack,
    this.isSubmitting = false,
    super.key,
  });

  final Future<void> Function(String email) onSubmit;
  final VoidCallback onBack;
  final bool isSubmitting;

  @override
  State<ForgotPasswordForm> createState() => ForgotPasswordFormState();
}

class ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final formKey = GlobalKey<ShadFormState>();

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final email = ((form.value['email'] as String?) ?? '').trim();
    await widget.onSubmit(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reset password', style: theme.textTheme.h3),
          const SizedBox(height: 4),
          Text(
            'Enter your email and we will send you a new password.',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 20),
          ShadInputFormField(
            id: 'email',
            label: const Text('Email'),
            placeholder: const Text('you@example.com'),
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            enabled: !widget.isSubmitting,
            validator: UserFormValidators.email,
            onSubmitted: (_) => widget.isSubmitting ? null : handleSubmit(),
          ),
          const SizedBox(height: 16),
          ShadButton(
            onPressed: widget.isSubmitting ? null : handleSubmit,
            child: Text(widget.isSubmitting ? 'Sending…' : 'Send reset email'),
          ),
          const SizedBox(height: 8),
          ShadButton.link(
            onPressed: widget.isSubmitting ? null : widget.onBack,
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}
