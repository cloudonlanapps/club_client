import 'package:flutter/material.dart';

import '../widgets/login_view.dart';

/// Thin screen wrapper around [LoginView]. Owns no state — exists so
/// the host router mounts a `*Screen` for `/auth/login` instead of a
/// view directly, matching the workspace's router → screen → view
/// convention.
class LoginScreen extends StatelessWidget {
  const LoginScreen({
    required this.onLoginSuccess,
    required this.onNavigateToForgotPassword,
    required this.onNavigateToSignup,
    super.key,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToForgotPassword;
  final VoidCallback onNavigateToSignup;

  @override
  Widget build(BuildContext context) {
    return LoginView(
      onLoginSuccess: onLoginSuccess,
      onNavigateToForgotPassword: onNavigateToForgotPassword,
      onNavigateToSignup: onNavigateToSignup,
    );
  }
}
