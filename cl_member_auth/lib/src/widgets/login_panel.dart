import 'package:cl_club_forms/cl_club_forms.dart'
    show LoginForm, LoginFormState;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/auth_view_sizes.dart';
import '../constants/auth_view_strings.dart';

/// The sign-in panel of `LoginView`: heading, the [LoginForm], the
/// forgot-password link, the Sign in action and the sign-up link.
///
/// The view holds [formKey] and the in-flight flag; [onSubmit] is its Sign
/// in action.
class LoginPanel extends StatelessWidget {
  const LoginPanel({
    required this.formKey,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignUp,
    super.key,
  });

  /// Key of the form the view validates.
  final GlobalKey<LoginFormState> formKey;

  /// Whether a sign-in is in flight; turns the form and the actions off.
  final bool isSubmitting;

  /// The Sign in action.
  final VoidCallback onSubmit;

  /// Opens the forgot-password view.
  final VoidCallback onForgotPassword;

  /// Opens the sign-up view.
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AuthViewStrings.signIn, style: theme.textTheme.h3),
        const SizedBox(height: AuthViewSizes.headingGap),
        Text(AuthViewStrings.signInIntro, style: theme.textTheme.p),
        const SizedBox(height: AuthViewSizes.sectionGap),
        LoginForm(key: formKey, enabled: !isSubmitting),
        const SizedBox(height: AuthViewSizes.linkGap),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton.link(
            onPressed: isSubmitting ? null : onForgotPassword,
            child: const Text(AuthViewStrings.forgotPassword),
          ),
        ),
        const SizedBox(height: AuthViewSizes.buttonGap),
        ShadButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: Text(
            isSubmitting ? AuthViewStrings.signingIn : AuthViewStrings.signIn,
          ),
        ),
        const SizedBox(height: AuthViewSizes.linkGap),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AuthViewStrings.noAccount, style: theme.textTheme.p),
            ShadButton.link(
              onPressed: isSubmitting ? null : onSignUp,
              child: const Text(AuthViewStrings.signUp),
            ),
          ],
        ),
      ],
    );
  }
}
