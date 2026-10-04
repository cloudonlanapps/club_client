import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/user_form/user_form_assembly.dart';
import 'package:ui_lib/src/widgets/user_form/user_form_validators.dart';

import 'username_availability_field.dart';

/// Result of a [SignupForm.onSubmit] call.
///
/// The form never catches exceptions — the caller owns the SDK call and
/// reports the outcome via this struct.
///
/// - **Success**: `const SignupSubmitResult()` (both fields empty). The
///   form calls `onSubmitSuccess()`.
/// - **Failure**: populate [fieldErrors] with `fieldId → message` pairs
///   (the form calls `setFieldError` for each) and/or [formError] for a
///   destructive toast. Recognised field IDs: `username`, `password`,
///   `confirmPassword`, `firstName`, `middleName`, `lastName`, `gender`,
///   `dateOfBirthUtc`, `phone`, `email`.
class SignupSubmitResult {
  const SignupSubmitResult({
    this.fieldErrors = const {},
    this.formError,
  });

  /// Field-id → error message. The form calls `setFieldError` for each.
  final Map<String, String> fieldErrors;

  /// Non-field-specific error, rendered as a destructive toast.
  final String? formError;

  bool get isSuccess => fieldErrors.isEmpty && formError == null;
}

/// Gender options exposed by [SignupForm]. Form-local so the widget
/// does not import SDK types directly. The caller maps to the SDK enum
/// before invoking the register call.
enum SignupGender {
  male,
  female,
  other,
  preferNotToSay;

  /// Human-readable display label.
  String get label {
    return switch (this) {
      SignupGender.male => 'Male',
      SignupGender.female => 'Female',
      SignupGender.other => 'Other',
      SignupGender.preferNotToSay => 'Prefer not to say',
    };
  }
}

/// Domain-agnostic registration-shaped form.
///
/// The form's behaviour is driven by whether [username] is supplied:
///
/// - `username == null` → editable username field + password +
///   confirm-password fields visible. CTA reads "Create account".
///   `onCheckUsernameAvailable` is invoked as the user types.
///   `onSubmit` receives non-null `username` and `password`.
///
/// - `username != null` → the supplied value is shown read-only at the
///   top of the form. Password fields are hidden. CTA reads
///   "Submit changes". `onCheckUsernameAvailable` is never invoked.
///   `onSubmit` receives `username == null` and `password == null`.
///
/// All registration fields (names, gender, DOB, phone, email) are always
/// editable. Pre-fill via [initialValues] (field id → value).
class SignupForm extends StatefulWidget {
  const SignupForm({
    required this.username,
    required this.initialValues,
    required this.onSubmit,
    required this.onSubmitSuccess,
    required this.onCheckUsernameAvailable,
    this.banner,
    this.onNavigateToLogin,
    this.identityDocumentsRequired,
    super.key,
  });

  /// Whether the server asks new members for identity documents after
  /// signup, or null while unknown. Only a confirmed `true` mentions them.
  final bool? identityDocumentsRequired;

  /// Mode discriminator. `null` → editable signup; non-null → reapply
  /// (username pinned, password hidden).
  final String? username;

  /// Pre-fill values keyed by field id. `null` means an empty form.
  final Map<String, dynamic>? initialValues;

  /// Optional callout rendered above the form. Used to surface an
  /// admin's reapply note to the user.
  final String? banner;

  /// Performs the registration / reapply. The form assembles the
  /// values and hands them to this callback, which owns the SDK call
  /// and any error translation.
  final Future<SignupSubmitResult> Function({
    required String email,
    required String phone,
    required DateTime dateOfBirthUtc,
    required SignupGender gender,
    String? username,
    String? password,
    String? firstName,
    String? middleName,
    String? lastName,
  })
  onSubmit;

  /// Called after [onSubmit] returns `isSuccess`.
  final VoidCallback onSubmitSuccess;

  /// Resolves to `true` when the username is available, `false` when
  /// taken. Only invoked when [username] is null; in reapply mode the
  /// form passes its parameter through but never calls it.
  final Future<bool> Function(String username) onCheckUsernameAvailable;

  /// Optional "Already have an account? Sign in" link. Hidden when
  /// `null` or when the form is in reapply mode.
  final VoidCallback? onNavigateToLogin;

  @override
  State<SignupForm> createState() => SignupFormState();
}

class SignupFormState extends State<SignupForm> {
  final formKey = GlobalKey<ShadFormState>();
  bool isSubmitting = false;

  /// Latest username text the field has reported (signup mode only).
  String currentUsername = '';

  /// The username whose availability has been confirmed by the
  /// embedded [UsernameAvailabilityField]. `canSubmit` requires this
  /// to equal [currentUsername] in signup mode.
  String? confirmedAvailableUsername;

  bool get _isUsernameLocked => widget.username != null;

  void onAvailabilityChanged(String username, String? confirmed) {
    if (!mounted) return;
    setState(() {
      currentUsername = username;
      confirmedAvailableUsername = confirmed;
    });
  }

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final v = form.value;

    // Cross-field validation: at least one of firstName or lastName.
    final nameError = UserFormValidators.atLeastOneName(
      (v['firstName'] as String?)?.trim(),
      (v['lastName'] as String?)?.trim(),
    );
    if (nameError != null) {
      form.setFieldError('firstName', nameError);
      return;
    }

    String? username;
    String? password;
    if (!_isUsernameLocked) {
      username = (v['username'] as String).trim();
      password = v['password'] as String;
      final confirmPassword = (v['confirmPassword'] as String?) ?? '';
      if (confirmPassword != password) {
        form.setFieldError('confirmPassword', 'Passwords do not match');
        return;
      }
    }

    final email = (v['email'] as String).trim();
    final firstName = ((v['firstName'] as String?)?.trim().isEmpty ?? true)
        ? null
        : (v['firstName'] as String).trim();
    final middleName = ((v['middleName'] as String?)?.trim().isEmpty ?? true)
        ? null
        : (v['middleName'] as String).trim();
    final lastName = ((v['lastName'] as String?)?.trim().isEmpty ?? true)
        ? null
        : (v['lastName'] as String).trim();
    final phone = (v['phone'] as String).trim();
    final dateOfBirthUtc = UserFormAssembly.floorToUtcMidnight(
      v['dateOfBirthUtc'] as DateTime?,
    )!;
    final gender = v['gender'] as SignupGender;

    setState(() => isSubmitting = true);
    final result = await widget.onSubmit(
      username: username,
      password: password,
      email: email,
      phone: phone,
      dateOfBirthUtc: dateOfBirthUtc,
      gender: gender,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
    );
    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (result.isSuccess) {
      widget.onSubmitSuccess();
      return;
    }

    for (final entry in result.fieldErrors.entries) {
      form.setFieldError(entry.key, entry.value);
    }
    final formError = result.formError;
    if (formError != null) showError(formError);
  }

  bool get canSubmit {
    if (isSubmitting) return false;
    if (_isUsernameLocked) return true;
    return currentUsername.isNotEmpty &&
        confirmedAvailableUsername == currentUsername;
  }

  void showError(String msg) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return ShadForm(
      key: formKey,
      initialValue: widget.initialValues ?? const <String, dynamic>{},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isUsernameLocked
                ? 'Update your registration'
                : 'Create an account',
            style: theme.textTheme.h3,
          ),
          const SizedBox(height: 4),
          Text(
            _isUsernameLocked
                ? 'Update the fields below and submit your changes.'
                : widget.identityDocumentsRequired ?? false
                ? 'Sign up to request access. After creating an account '
                      "you'll be asked to upload identity documents for "
                      'admin review.'
                : 'Sign up to request access. An admin will review your '
                      'application.',
            style: theme.textTheme.p,
          ),
          if (widget.banner != null && widget.banner!.isNotEmpty) ...[
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: cs.border),
                borderRadius: BorderRadius.circular(8),
                color: cs.muted,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.banner!,
                  style: theme.textTheme.small,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_isUsernameLocked) ...[
            ReadOnlyUsername(username: widget.username!),
            const SizedBox(height: 12),
          ] else ...[
            UsernameAvailabilityField(
              label: requiredLabel('Username'),
              placeholder: const Text('unique-username'),
              autofocus: true,
              enabled: !isSubmitting,
              validator: UserFormValidators.username,
              onAvailabilityChanged: onAvailabilityChanged,
              checkAvailability: widget.onCheckUsernameAvailable,
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              id: 'password',
              label: requiredLabel('Password'),
              placeholder: const Text('At least 8 characters'),
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              obscureText: true,
              enabled: !isSubmitting,
              validator: UserFormValidators.password,
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              id: 'confirmPassword',
              label: requiredLabel('Confirm password'),
              placeholder: const Text('Re-type password'),
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              obscureText: true,
              enabled: !isSubmitting,
              validator: (v) =>
                  v.isEmpty ? 'Please confirm the password' : null,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: ShadInputFormField(
                  id: 'firstName',
                  label: requiredLabel('First name'),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !isSubmitting,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShadInputFormField(
                  id: 'middleName',
                  label: const Text('Middle name'),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  enabled: !isSubmitting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'lastName',
            label: requiredLabel('Last name'),
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            enabled: !isSubmitting,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ShadSelectFormField<SignupGender>(
                  id: 'gender',
                  label: requiredLabel('Gender'),
                  placeholder: const Text('Select'),
                  enabled: !isSubmitting,
                  validator: UserFormValidators.gender,
                  options: SignupGender.values
                      .map(
                        (g) => ShadOption(
                          value: g,
                          child: Text(g.label),
                        ),
                      )
                      .toList(),
                  selectedOptionBuilder: (context, value) => Text(value.label),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CLDatePickerFormField(
                  id: 'dateOfBirthUtc',
                  label: requiredLabel('Date of birth'),
                  placeholder: const Text('Pick date'),
                  enabled: !isSubmitting,
                  formatDate: (d) => DateFormat('d MMM yyyy').format(d),
                  validator: UserFormValidators.dateOfBirth,
                  yearsBefore: 100,
                  yearsAfter: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'phone',
            label: requiredLabel('Phone'),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !isSubmitting,
            validator: UserFormValidators.phone,
          ),
          const SizedBox(height: 12),
          ShadInputFormField(
            id: 'email',
            label: requiredLabel('Email'),
            placeholder: const Text('name@example.com'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            enabled: !isSubmitting,
            validator: UserFormValidators.email,
          ),
          const SizedBox(height: 20),
          ShadButton(
            onPressed: canSubmit ? handleSubmit : null,
            child: Text(
              isSubmitting
                  ? 'Submitting…'
                  : (_isUsernameLocked ? 'Submit changes' : 'Create account'),
            ),
          ),
          if (!_isUsernameLocked && widget.onNavigateToLogin != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: theme.textTheme.p,
                ),
                ShadButton.link(
                  onPressed: isSubmitting ? null : widget.onNavigateToLogin,
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ReadOnlyUsername extends StatelessWidget {
  const ReadOnlyUsername({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Username', style: theme.textTheme.small),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: cs.border),
            borderRadius: BorderRadius.circular(6),
            color: cs.muted,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(username, style: theme.textTheme.p),
          ),
        ),
      ],
    );
  }
}

/// Builds a label widget with a red asterisk for required fields.
Widget requiredLabel(String text) {
  return Text.rich(
    TextSpan(
      text: text,
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: Colors.red),
        ),
      ],
    ),
  );
}
