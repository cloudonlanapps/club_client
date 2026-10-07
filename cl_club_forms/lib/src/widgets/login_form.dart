import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Pure-UI username/password form (no SDK / no Riverpod). Calls [onSubmit]
/// when validation passes.
///
/// The hosting widget owns the loading flag (so it can disable the form while
/// a request is in flight) and navigation to "forgot password" / "sign up".
class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignUp,
    this.isSubmitting = false,
    super.key,
  });

  final Future<void> Function(String username, String password) onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final bool isSubmitting;

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final formKey = GlobalKey<ShadFormState>();

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final values = form.value;
    final username = (values['username'] as String?)?.trim() ?? '';
    final password = (values['password'] as String?) ?? '';
    await widget.onSubmit(username, password);
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
          Text('Sign in', style: theme.textTheme.h3),
          const SizedBox(height: 4),
          Text(
            'Enter your username and password to continue.',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 20),
          ShadInputFormField(
            id: 'username',
            label: const Text('Username'),
            placeholder: const Text('your-username'),
            autofocus: true,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.next,
            enabled: !widget.isSubmitting,
            validator: (v) => v.trim().isEmpty ? 'Username is required' : null,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'password',
            label: const Text('Password'),
            placeholder: const Text('••••••••'),
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            enabled: !widget.isSubmitting,
            validator: (v) => v.isEmpty ? 'Password is required' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.link(
              onPressed: widget.isSubmitting ? null : widget.onForgotPassword,
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 12),
          ShadButton(
            onPressed: widget.isSubmitting ? null : handleSubmit,
            child: Text(widget.isSubmitting ? 'Signing in…' : 'Sign in'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?", style: theme.textTheme.p),
              ShadButton.link(
                onPressed: widget.isSubmitting ? null : widget.onSignUp,
                child: const Text('Sign up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
