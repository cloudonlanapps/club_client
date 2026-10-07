import 'package:cl_club_forms/cl_club_forms.dart'
    show ForgotPasswordForm, ForgotPasswordFormState;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/auth_view_sizes.dart';
import '../constants/auth_view_strings.dart';

/// The request panel of `ForgotPasswordView`: heading, the
/// [ForgotPasswordForm], the Send action and the link back to sign in.
///
/// The view holds [formKey] and the in-flight flag; [onSubmit] is its Send
/// action, which Enter in the form's field calls too.
class ForgotPasswordPanel extends StatelessWidget {
  const ForgotPasswordPanel({
    required this.formKey,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
    super.key,
  });

  /// Key of the form the view validates.
  final GlobalKey<ForgotPasswordFormState> formKey;

  /// Whether a request is in flight; turns the form and the actions off.
  final bool isSubmitting;

  /// The Send action.
  final VoidCallback onSubmit;

  /// Returns to sign in.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AuthViewStrings.resetPassword, style: theme.textTheme.h3),
        const SizedBox(height: AuthViewSizes.headingGap),
        Text(AuthViewStrings.resetPasswordIntro, style: theme.textTheme.p),
        const SizedBox(height: AuthViewSizes.sectionGap),
        ForgotPasswordForm(
          key: formKey,
          enabled: !isSubmitting,
          onSubmitted: isSubmitting ? null : onSubmit,
        ),
        const SizedBox(height: AuthViewSizes.actionGap),
        ShadButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: Text(
            isSubmitting
                ? AuthViewStrings.sending
                : AuthViewStrings.sendResetEmail,
          ),
        ),
        const SizedBox(height: AuthViewSizes.linkGap),
        ShadButton.link(
          onPressed: isSubmitting ? null : onBack,
          child: const Text(AuthViewStrings.backToSignIn),
        ),
      ],
    );
  }
}
