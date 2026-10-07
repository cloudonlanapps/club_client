import 'package:cl_club_forms/cl_club_forms.dart'
    show ForgotPasswordFormFields, ForgotPasswordFormState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/auth_view_sizes.dart';
import '../constants/auth_view_strings.dart';
import '../providers/auth.dart';
import 'forgot_password_confirmation_panel.dart';
import 'forgot_password_panel.dart';

/// Connected self-service "forgot password" view — no Scaffold.
///
/// Hosts the SDK-free `ForgotPasswordForm` with its heading, its Send
/// action and the link back to sign in, and wires it to
/// [authStateProvider]. The server never reveals whether the email matches
/// a member, so on success this view shows a deliberately speculative
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

/// State of [ForgotPasswordView]: holds the form's key, the in-flight flag
/// and whether the request went out.
class ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  /// Key of the forgot-password form.
  final formKey = GlobalKey<ForgotPasswordFormState>();

  /// Whether a request is in flight.
  bool isSubmitting = false;

  /// Whether a request went out; swaps the form for the confirmation.
  bool requestSent = false;

  /// The Send action: validates the form and requests the reset.
  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    final email = values[ForgotPasswordFormFields.emailId] as String;

    setState(() => isSubmitting = true);
    var success = false;
    try {
      final override = widget.onResetPassword;
      if (override != null) {
        await override(email);
      } else {
        await ref.read(authStateProvider.notifier).resetPassword(email);
      }
      success = true;
    } on Object catch (_) {
      showError(AuthViewStrings.resetFailed);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (success && mounted) setState(() => requestSent = true);
  }

  /// Shows [message] as a failure toast.
  void showError(String message) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AuthViewSizes.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AuthViewSizes.padding),
          child: requestSent
              ? ForgotPasswordConfirmationPanel(
                  onNavigateToLogin: widget.onNavigateToLogin,
                )
              : ForgotPasswordPanel(
                  formKey: formKey,
                  isSubmitting: isSubmitting,
                  onSubmit: submit,
                  onBack: widget.onNavigateToLogin,
                ),
        ),
      ),
    );
  }
}
