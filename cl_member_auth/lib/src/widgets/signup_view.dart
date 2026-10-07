import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupForm, SignupFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider, identityVerificationProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/auth_view_sizes.dart';
import '../constants/auth_view_strings.dart';
import '../models/signup_form_helpers.dart';
import '../providers/client.dart';
import '../providers/username_availability.dart';

/// Self-service signup view.
///
/// Hosts the SDK-free [SignupForm] with its heading, the Create account
/// action and the link to sign in. It validates the form, registers through
/// `clientProvider`, holds the in-flight flag, and puts what the server
/// refuses back on the form's fields.
///
/// On a successful `client.auth.register` the view invokes
/// [onSignupSuccess]. The host routes that to `/auth/signup-success` so
/// the new (still logged-out) user gets an explicit acknowledgement.
/// This view never mutates auth state.
class SignupView extends ConsumerStatefulWidget {
  const SignupView({
    required this.onSignupSuccess,
    required this.onNavigateToLogin,
    super.key,
  });

  /// Called after `client.auth.register` succeeds. The account exists
  /// but the user is still logged out.
  final VoidCallback onSignupSuccess;

  /// Called when the user taps the "Sign in" link.
  final VoidCallback onNavigateToLogin;

  @override
  ConsumerState<SignupView> createState() => SignupViewState();
}

/// State of [SignupView]: holds the form's key, the in-flight flag and
/// whether the form may be submitted.
class SignupViewState extends ConsumerState<SignupView> {
  /// Key of the signup form.
  final formKey = GlobalKey<SignupFormState>();

  /// Whether a registration is in flight.
  bool isSubmitting = false;

  /// Whether the form may be submitted: its username is confirmed
  /// available.
  bool canSubmit = false;

  /// Whether [username] is free to register.
  Future<bool> checkUsernameAvailable(String username) async {
    final result = await ref.read(
      usernameAvailabilityProvider(username).future,
    );
    return result == UsernameAvailability.available;
  }

  /// The Create account action: validates the form and registers.
  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;

    setState(() => isSubmitting = true);
    var success = false;
    try {
      final client = await ref.read(clientProvider.future);
      await SignupFormSubmit.create(
        auth: client.auth,
        defaultCountryCode: ref.read(defaultCountryCodeProvider),
        values: values,
      );
      success = true;
    } on Object catch (error) {
      final fieldErrors = SignupFormSubmit.fieldErrorsFor(error);
      formKey.currentState?.showErrors(fieldErrors: fieldErrors);
      if (fieldErrors.isEmpty) {
        showError(SignupFormSubmit.createFailedMessage);
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (success && mounted) widget.onSignupSuccess();
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
    final theme = ShadTheme.of(context);
    final documentsRequired = ref.watch(identityVerificationProvider) ?? false;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AuthViewSizes.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AuthViewSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AuthViewStrings.createAnAccount, style: theme.textTheme.h3),
              const SizedBox(height: AuthViewSizes.headingGap),
              Text(
                documentsRequired
                    ? AuthViewStrings.signUpIntroWithDocuments
                    : AuthViewStrings.signUpIntro,
                style: theme.textTheme.p,
              ),
              const SizedBox(height: AuthViewSizes.sectionGap),
              SignupForm(
                key: formKey,
                enabled: !isSubmitting,
                onCheckUsernameAvailable: checkUsernameAvailable,
                onCanSubmitChanged: (value) {
                  if (canSubmit != value) setState(() => canSubmit = value);
                },
              ),
              const SizedBox(height: AuthViewSizes.sectionGap),
              ShadButton(
                onPressed: canSubmit && !isSubmitting ? submit : null,
                child: Text(
                  isSubmitting
                      ? AuthViewStrings.submitting
                      : AuthViewStrings.createAccount,
                ),
              ),
              const SizedBox(height: AuthViewSizes.linkGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AuthViewStrings.haveAccount, style: theme.textTheme.p),
                  ShadButton.link(
                    onPressed: isSubmitting ? null : widget.onNavigateToLogin,
                    child: const Text(AuthViewStrings.signIn),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
