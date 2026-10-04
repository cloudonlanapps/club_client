import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Acknowledgment view rendered after a successful self-service signup.
///
/// The signup flow no longer auto-logs the new user in; instead the host
/// navigates here so the user gets an explicit "account created — sign in
/// to continue" confirmation, then taps through to the login screen.
///
/// Body-only — the surrounding `AuthShell` (mounted at the `/auth/**`
/// `ShellRoute`) supplies hero + footer chrome.
class SignupSuccessView extends StatelessWidget {
  const SignupSuccessView({
    required this.onHome,
    this.identityVerification,
    super.key,
  });

  /// Called when the user taps the primary "Continue" button. The host
  /// wires this to `context.go('/auth/login')`.
  final VoidCallback onHome;

  /// Whether the server asks new members for an identity document, or null
  /// while unknown. Only a confirmed `true` promises a document step (#84).
  final bool? identityVerification;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 56,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Account created',
                style: theme.textTheme.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                identityVerification ?? false
                    ? "Sign in with your new account to continue. We'll guide "
                          'you through the document-upload step from there.'
                    : 'Sign in with your new account to continue. An admin '
                          'will review your application.',
                style: theme.textTheme.p,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: onHome,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
