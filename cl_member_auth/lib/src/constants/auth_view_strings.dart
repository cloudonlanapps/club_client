/// Text of the views that host an account form: sign in, sign up, forgot
/// password and change password.
abstract final class AuthViewStrings {
  /// Heading of the sign-in view, and label of its submit action.
  static const String signIn = 'Sign in';

  /// Line under the sign-in heading.
  static const String signInIntro =
      'Enter your username and password to continue.';

  /// Label of the sign-in action while it runs.
  static const String signingIn = 'Signing in…';

  /// Link from sign in to the forgot-password view.
  static const String forgotPassword = 'Forgot password?';

  /// Lead-in to the sign-up link.
  static const String noAccount = "Don't have an account?";

  /// Link from sign in to sign up.
  static const String signUp = 'Sign up';

  /// Heading of the change-password view.
  static const String changePassword = 'Change password';

  /// Label of the change-password submit action.
  static const String updatePassword = 'Update password';

  /// Label of the change-password action while it runs.
  static const String saving = 'Saving…';

  /// Label of the action that leaves a view without saving.
  static const String cancel = 'Cancel';

  /// Shown once the password is changed.
  static const String passwordUpdated = 'Password updated.';

  /// Shown on the current-password field when the server refuses it.
  static const String currentPasswordIncorrect =
      'Current password is incorrect';

  /// Shown when changing the password fails for another reason.
  static const String changePasswordFailed =
      'Could not change password. Please try again.';

  /// Heading of the forgot-password view.
  static const String resetPassword = 'Reset password';

  /// Line under the forgot-password heading.
  static const String resetPasswordIntro =
      'Enter your email and we will send you a new password.';

  /// Label of the forgot-password submit action.
  static const String sendResetEmail = 'Send reset email';

  /// Label of the forgot-password action while it runs.
  static const String sending = 'Sending…';

  /// Link, and confirmation action, back to sign in.
  static const String backToSignIn = 'Back to sign in';

  /// Shown when the reset request fails.
  static const String resetFailed =
      'Could not send the reset email. Please try again.';

  /// Heading of the confirmation after a reset request.
  static const String checkYourEmail = 'Check your email';

  /// The confirmation after a reset request; never says the email exists.
  static const String resetRequested =
      'If your email is in our member list, you will receive an email '
      'with a new password. If you have not received it within 24 hours, '
      'please contact an admin.';

  /// Heading of the sign-up view.
  static const String createAnAccount = 'Create an account';

  /// Line under the sign-up heading where new members upload identity
  /// documents.
  static const String signUpIntroWithDocuments =
      'Sign up to request access. After creating an account '
      "you'll be asked to upload identity documents for "
      'admin review.';

  /// Line under the sign-up heading otherwise.
  static const String signUpIntro =
      'Sign up to request access. An admin will review your '
      'application.';

  /// Label of the sign-up submit action.
  static const String createAccount = 'Create account';

  /// Label of the sign-up action while it runs.
  static const String submitting = 'Submitting…';

  /// Lead-in to the sign-in link.
  static const String haveAccount = 'Already have an account?';
}
