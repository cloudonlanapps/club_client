import 'package:cl_club_forms/cl_club_forms.dart' show SignupForm;
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider, identityVerificationProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/signup_form_helpers.dart';
import '../providers/client.dart';
import '../providers/username_availability.dart';

/// Self-service signup view.
///
/// Wraps the domain-agnostic [SignupForm] from `ui_lib` with the
/// standard vertical scroll chrome and resolves the SDK-bound callbacks
/// internally via `clientProvider` and `usernameAvailabilityProvider`.
///
/// On a successful `client.auth.register` the form invokes
/// [onSignupSuccess]. The host routes that to `/auth/signup-success` so
/// the new (still logged-out) user gets an explicit acknowledgement.
/// This view never mutates auth state.
class SignupView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SignupForm(
              username: null,
              initialValues: null,
              identityDocumentsRequired: ref.watch(
                identityVerificationProvider,
              ),
              onNavigateToLogin: onNavigateToLogin,
              onCheckUsernameAvailable: (username) async {
                final result = await ref.read(
                  usernameAvailabilityProvider(username).future,
                );
                return result == UsernameAvailability.available;
              },
              onSubmit:
                  ({
                    required email,
                    required phone,
                    required dateOfBirthUtc,
                    required gender,
                    username,
                    password,
                    firstName,
                    middleName,
                    lastName,
                  }) async {
                    final client = await ref.read(clientProvider.future);
                    return SignupFormSubmit.create(
                      auth: client.auth,
                      defaultCountryCode: ref.read(defaultCountryCodeProvider),
                      username: username!,
                      password: password!,
                      email: email,
                      phone: phone,
                      dateOfBirthUtc: dateOfBirthUtc,
                      gender: gender,
                      firstName: firstName,
                      middleName: middleName,
                      lastName: lastName,
                    );
                  },
              onSubmitSuccess: onSignupSuccess,
            ),
          ),
        ),
      ),
    );
  }
}
