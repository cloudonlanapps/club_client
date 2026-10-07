import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/auth_view_sizes.dart';
import '../constants/auth_view_strings.dart';

/// Speculative confirmation shown after a reset request — never confirms
/// the email exists.
class ForgotPasswordConfirmationPanel extends StatelessWidget {
  const ForgotPasswordConfirmationPanel({
    required this.onNavigateToLogin,
    super.key,
  });

  /// Returns to sign in.
  final VoidCallback onNavigateToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AuthViewStrings.checkYourEmail, style: theme.textTheme.h3),
        const SizedBox(height: AuthViewSizes.buttonGap),
        Text(AuthViewStrings.resetRequested, style: theme.textTheme.p),
        const SizedBox(height: AuthViewSizes.sectionGap),
        ShadButton(
          onPressed: onNavigateToLogin,
          child: const Text(AuthViewStrings.backToSignIn),
        ),
      ],
    );
  }
}
