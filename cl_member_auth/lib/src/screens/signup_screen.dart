import 'package:flutter/material.dart';

import '../widgets/signup_view.dart';

/// Thin screen wrapper around [SignupView].
class SignupScreen extends StatelessWidget {
  const SignupScreen({
    required this.onSignupSuccess,
    required this.onNavigateToLogin,
    super.key,
  });

  final VoidCallback onSignupSuccess;
  final VoidCallback onNavigateToLogin;

  @override
  Widget build(BuildContext context) {
    return SignupView(
      onSignupSuccess: onSignupSuccess,
      onNavigateToLogin: onNavigateToLogin,
    );
  }
}
