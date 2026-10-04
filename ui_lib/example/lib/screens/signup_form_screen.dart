import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Demo screen for [SignupForm].
///
/// Wires stub callbacks so the form is fully exercisable without an
/// auth backend:
///
/// - **Username availability**: anything matching `taken*` reports as
///   taken; everything else reports as available after a short delay.
/// - **Signup**: `dupuser*` / `dupemail*` usernames return a failure
///   result attached to the relevant field; anything else succeeds.
class SignupFormScreen extends StatelessWidget {
  const SignupFormScreen({super.key});

  Future<bool> _checkAvailability(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return !username.toLowerCase().startsWith('taken');
  }

  Future<SignupSubmitResult> _onSubmit({
    required String email,
    required String phone,
    required DateTime dateOfBirthUtc,
    required SignupGender gender,
    String? username,
    String? password,
    String? firstName,
    String? middleName,
    String? lastName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final u = (username ?? '').toLowerCase();
    if (u.startsWith('dupuser')) {
      return const SignupSubmitResult(
        fieldErrors: {'username': 'That username is already taken.'},
      );
    }
    if (u.startsWith('dupemail')) {
      return const SignupSubmitResult(
        fieldErrors: {'email': 'That email is already registered.'},
      );
    }
    return const SignupSubmitResult();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SignupForm(
              username: null,
              initialValues: null,
              onSubmitSuccess: () => ShadToaster.of(context).show(
                const ShadToast(
                  description: Text(
                    'Signup success — host would route to acknowledgement',
                  ),
                ),
              ),
              onNavigateToLogin: () => ShadToaster.of(context).show(
                const ShadToast(
                  description: Text('Navigate to login — host would route'),
                ),
              ),
              onCheckUsernameAvailable: _checkAvailability,
              onSubmit: _onSubmit,
            ),
          ),
        ),
      ),
    );
  }
}
