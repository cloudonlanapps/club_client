import 'package:cl_remote_store/cl_remote_store.dart'
    show identityVerificationProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Gender, SdkErrorCode, ServerException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart'
    show SignupForm, SignupGender, SignupSubmitResult;

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
                    try {
                      await client.auth.register(
                        username: username!,
                        email: email,
                        password: password!,
                        phone: phone,
                        dateOfBirthUtc: dateOfBirthUtc,
                        gender: gender.toSdkGender(),
                        firstName: firstName,
                        middleName: middleName,
                        lastName: lastName,
                      );
                      return const SignupSubmitResult();
                    } on ServerException catch (e) {
                      return resultFor(e.code);
                    } on Object catch (_) {
                      return const SignupSubmitResult(
                        formError:
                            'Could not create account. Please try again.',
                      );
                    }
                  },
              onSubmitSuccess: onSignupSuccess,
            ),
          ),
        ),
      ),
    );
  }
}

SignupSubmitResult resultFor(String? code) {
  if (code == SdkErrorCode.duplicateUsername) {
    return const SignupSubmitResult(
      fieldErrors: {'username': 'That username is already taken.'},
    );
  }
  if (code == SdkErrorCode.duplicateEmail) {
    return const SignupSubmitResult(
      fieldErrors: {'email': 'That email is already registered.'},
    );
  }
  return const SignupSubmitResult(
    formError: 'Could not create account. Please try again.',
  );
}

extension on SignupGender {
  Gender toSdkGender() {
    return switch (this) {
      SignupGender.male => Gender.male,
      SignupGender.female => Gender.female,
      SignupGender.other => Gender.other,
      SignupGender.preferNotToSay => Gender.preferNotToSay,
    };
  }
}
