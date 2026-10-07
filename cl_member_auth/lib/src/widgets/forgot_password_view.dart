import 'package:cl_club_forms/cl_club_forms.dart' show ForgotPasswordForm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/auth.dart';

/// Connected self-service "forgot password" view — no Scaffold.
///
/// Wraps the SDK-free [ForgotPasswordForm] and wires it to
/// [authStateProvider]. The server never reveals whether the email matches a
/// member, so on success this view shows a deliberately speculative
/// confirmation rather than asserting an email was sent.
class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({
    required this.onNavigateToLogin,
    this.onResetPassword,
    super.key,
  });

  /// Called when the user returns to sign in (from the form or the
  /// confirmation panel).
  final VoidCallback onNavigateToLogin;

  /// Optional action override: if provided, replaces the default
  /// `authStateProvider.notifier.resetPassword()` call.
  final Future<void> Function(String email)? onResetPassword;

  @override
  ConsumerState<ForgotPasswordView> createState() => ForgotPasswordViewState();
}

class ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  bool isSubmitting = false;
  bool requestSent = false;

  Future<void> _handleSubmit(String email) async {
    setState(() => isSubmitting = true);
    var success = false;
    try {
      if (widget.onResetPassword != null) {
        await widget.onResetPassword!(email);
      } else {
        await ref.read(authStateProvider.notifier).resetPassword(email);
      }
      success = true;
    } on Object catch (_) {
      _showError('Could not send the reset email. Please try again.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (success && mounted) setState(() => requestSent = true);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: requestSent
              ? _ConfirmationPanel(onNavigateToLogin: widget.onNavigateToLogin)
              : ForgotPasswordForm(
                  isSubmitting: isSubmitting,
                  onSubmit: _handleSubmit,
                  onBack: widget.onNavigateToLogin,
                ),
        ),
      ),
    );
  }
}

/// Speculative confirmation shown after a reset request — never confirms the
/// email exists.
class _ConfirmationPanel extends StatelessWidget {
  const _ConfirmationPanel({required this.onNavigateToLogin});

  final VoidCallback onNavigateToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Check your email', style: theme.textTheme.h3),
        const SizedBox(height: 12),
        Text(
          'If your email is in our member list, you will receive an email '
          'with a new password. If you have not received it within 24 hours, '
          'please contact an admin.',
          style: theme.textTheme.p,
        ),
        const SizedBox(height: 20),
        ShadButton(
          onPressed: onNavigateToLogin,
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}
