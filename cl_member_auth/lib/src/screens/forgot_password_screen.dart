import 'package:flutter/material.dart';

import '../widgets/forgot_password_view.dart';

/// Thin screen wrapper around [ForgotPasswordView].
///
/// Self-service password reset: the user enters their email and the server
/// emails a new password if the address matches a member. The view shows a
/// speculative confirmation that never reveals account existence.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({required this.onNavigateToLogin, super.key});

  final VoidCallback onNavigateToLogin;

  @override
  Widget build(BuildContext context) {
    return ForgotPasswordView(
      onNavigateToLogin: onNavigateToLogin,
    );
  }
}
