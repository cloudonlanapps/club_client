import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Demo screen for [SignupForm]: plays the host's part with a Create
/// account button that validates the form, and stands in for the auth
/// backend:
///
/// - **Username availability**: anything starting `taken` reports as taken;
///   everything else reports as available after a short delay.
/// - **Signup**: a `dupuser…` / `dupemail…` username is refused on the
///   username / email field, as the server refuses a duplicate; anything
///   else succeeds.
class SignupFormScreen extends StatefulWidget {
  const SignupFormScreen({super.key});

  @override
  State<SignupFormScreen> createState() => SignupFormScreenState();
}

/// State of [SignupFormScreen]: the form's key, the in-flight flag and
/// whether the form may be submitted.
class SignupFormScreenState extends State<SignupFormScreen> {
  /// Widest the form's column grows.
  static const double maxWidth = 420;

  /// Around the column.
  static const double padding = 24;

  /// Between the form and the button.
  static const double actionGap = 20;

  /// How long the stand-in availability check takes.
  static const Duration checkDelay = Duration(milliseconds: 400);

  /// How long the stand-in signup takes.
  static const Duration submitDelay = Duration(milliseconds: 600);

  /// Key of the signup form.
  final formKey = GlobalKey<SignupFormState>();

  /// Whether the stand-in signup is in flight.
  bool isSubmitting = false;

  /// Whether the form may be submitted.
  bool canSubmit = false;

  /// The stand-in availability check.
  Future<bool> checkAvailability(String username) async {
    await Future<void>.delayed(checkDelay);
    return !username.toLowerCase().startsWith('taken');
  }

  /// What the stand-in server refuses for [username], keyed by field id.
  Map<String, String> refusalFor(String username) {
    if (username.startsWith('dupuser')) {
      return const {
        UserFormFields.usernameId: 'That username is already taken.',
      };
    }
    if (username.startsWith('dupemail')) {
      return const {
        UserFormFields.emailId: 'That email is already registered.',
      };
    }
    return const {};
  }

  /// The Create account action: validates the form and "signs up".
  Future<void> handleSubmit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;

    setState(() => isSubmitting = true);
    await Future<void>.delayed(submitDelay);
    if (!mounted) return;
    setState(() => isSubmitting = false);

    final refusal = refusalFor(values[UserFormFields.usernameId] as String);
    if (refusal.isNotEmpty) {
      formKey.currentState?.showErrors(fieldErrors: refusal);
      return;
    }
    ShadToaster.of(context).show(
      const ShadToast(
        description: Text(
          'Signup success — host would route to acknowledgement',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: actionGap,
              children: [
                SignupForm(
                  key: formKey,
                  enabled: !isSubmitting,
                  onCheckUsernameAvailable: checkAvailability,
                  onCanSubmitChanged: (value) {
                    if (canSubmit != value) setState(() => canSubmit = value);
                  },
                ),
                ShadButton(
                  onPressed: canSubmit && !isSubmitting ? handleSubmit : null,
                  child: Text(isSubmitting ? 'Submitting…' : 'Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
