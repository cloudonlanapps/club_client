import 'dart:developer' as developer;

import 'package:cl_club_forms/cl_club_forms.dart'
    show LoginFormFields, LoginFormState;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/auth.dart';
import '../utils/login_error_messages.dart';
import 'account_blocked_view.dart';
import 'account_left_view.dart';
import 'loading_indicator.dart';
import 'login_panel.dart';

/// Login view — no Scaffold, returns content body only.
///
/// Branches on [authStateProvider]:
///   - loading            → loading indicator
///   - data == null       → login form
///   - data != null       → calls [onLoginSuccess]; the host router
///                          drives the status-aware destination
///                          (active → home, registered/pending →
///                          /onboarding/welcome)
///   - error: blocked     → AccountBlockedView
///   - error: left        → AccountLeftView
///   - error: other       → login form + error toast
///
/// Every message is fixed text from [LoginErrorMessages]; the raw error is
/// logged, never shown.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({
    required this.onLoginSuccess,
    required this.onNavigateToForgotPassword,
    required this.onNavigateToSignup,
    this.onLogin,
    super.key,
  });

  /// Called after login succeeds. The user is already stored in
  /// [authStateProvider].
  final VoidCallback onLoginSuccess;

  /// Called when user taps "Forgot password?".
  final VoidCallback onNavigateToForgotPassword;

  /// Called when user taps "Sign up".
  final VoidCallback onNavigateToSignup;

  /// Optional action override: if provided, replaces the default
  /// `authStateProvider.notifier.login()` call. The consumer can still call
  /// `authStateProvider.notifier.login()` from inside this callback to
  /// wrap/extend the default behavior.
  final Future<void> Function(String username, String password)? onLogin;

  @override
  ConsumerState<LoginView> createState() => LoginViewState();
}

/// State of [LoginView]: holds the form's key and the in-flight flag.
class LoginViewState extends ConsumerState<LoginView> {
  /// Key of the sign-in form.
  final formKey = GlobalKey<LoginFormState>();

  /// Whether a sign-in is in flight.
  bool isSubmitting = false;

  /// The Sign in action: validates the form and signs in with its values.
  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    await handleLogin(
      values[LoginFormFields.usernameId] as String,
      values[LoginFormFields.passwordId] as String,
    );
  }

  /// Signs in and reports the outcome.
  Future<void> handleLogin(String username, String password) async {
    setState(() => isSubmitting = true);

    if (widget.onLogin != null) {
      await widget.onLogin!(username, password);
    } else {
      await ref.read(authStateProvider.notifier).login(username, password);
    }

    if (!mounted) return;
    setState(() => isSubmitting = false);

    ref
        .read(authStateProvider)
        .when(
          data: (user) {
            if (user != null) widget.onLoginSuccess();
          },
          loading: () {},
          error: (e, _) => showErrorToast(e),
        );
  }

  void showErrorToast(Object error) {
    developer.log(
      'Login failed',
      name: 'cl_member_auth',
      error: error,
    );
    ShadToaster.of(context).show(
      ShadToast.destructive(
        description: Text(LoginErrorMessages.forError(error)),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  void resetAuth() {
    ref.invalidate(authStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Auto-redirect once we are logged in (covers the auto-restore case
    // where the user lands on the login view while already authenticated).
    ref.listen<AsyncValue<UserPrivate?>>(authStateProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null) widget.onLoginSuccess();
    });

    final auth = ref.watch(authStateProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: auth.when(
            loading: () => const LoadingIndicator(message: 'Signing you in…'),
            data: (user) {
              if (user != null) {
                return const LoadingIndicator(message: 'Redirecting…');
              }
              return LoginPanel(
                formKey: formKey,
                isSubmitting: isSubmitting,
                onSubmit: submit,
                onForgotPassword: widget.onNavigateToForgotPassword,
                onSignUp: widget.onNavigateToSignup,
              );
            },
            error: (error, _) {
              final code = error is SdkException ? error.code : null;
              if (code == SdkErrorCode.accountBlocked) {
                return AccountBlockedView(onBack: resetAuth);
              }
              if (code == SdkErrorCode.userNotFound ||
                  code == SdkErrorCode.accountLeft) {
                return AccountLeftView(onBack: resetAuth);
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    child: Text(
                      LoginErrorMessages.forError(error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  LoginPanel(
                    formKey: formKey,
                    isSubmitting: isSubmitting,
                    onSubmit: submit,
                    onForgotPassword: widget.onNavigateToForgotPassword,
                    onSignUp: widget.onNavigateToSignup,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
