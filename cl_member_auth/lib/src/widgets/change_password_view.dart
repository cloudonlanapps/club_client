import 'package:cl_club_forms/cl_club_forms.dart'
    show ChangePasswordForm, ChangePasswordFormFields, ChangePasswordFormState;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/auth_view_sizes.dart';
import '../constants/auth_view_strings.dart';
import '../providers/auth.dart';

/// Connected self-service "change my password" view — no Scaffold.
///
/// Hosts the SDK-free [ChangePasswordForm] in a card with its heading and
/// its Cancel and Update actions, and wires it to [authStateProvider]. A
/// current password the server refuses shows on that field. Can be used in
/// a screen, popover, or dialog.
class ChangePasswordView extends ConsumerStatefulWidget {
  const ChangePasswordView({
    required this.onSuccess,
    required this.onCancel,
    this.onChangePassword,
    super.key,
  });

  /// Called after the password is changed successfully.
  final VoidCallback onSuccess;

  /// Called when the user taps Cancel.
  final VoidCallback onCancel;

  /// Optional action override: if provided, replaces the default
  /// `authStateProvider.notifier.changePassword()` call.
  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })?
  onChangePassword;

  @override
  ConsumerState<ChangePasswordView> createState() => ChangePasswordViewState();
}

/// State of [ChangePasswordView]: holds the form's key and the in-flight
/// flag.
class ChangePasswordViewState extends ConsumerState<ChangePasswordView> {
  /// Key of the change-password form.
  final formKey = GlobalKey<ChangePasswordFormState>();

  /// Whether the change is in flight.
  bool isSubmitting = false;

  /// The Update action: validates the form and changes the password.
  Future<void> submit() async {
    final values = formKey.currentState?.validate();
    if (values == null) return;
    final current = values[ChangePasswordFormFields.currentId] as String;
    final next = values[ChangePasswordFormFields.nextId] as String;

    setState(() => isSubmitting = true);
    var success = false;
    try {
      final override = widget.onChangePassword;
      if (override != null) {
        await override(currentPassword: current, newPassword: next);
      } else {
        await ref
            .read(authStateProvider.notifier)
            .changePassword(currentPassword: current, newPassword: next);
      }
      success = true;
    } on Object catch (e) {
      // A current password the server refuses shows on its field; any
      // other failure, whatever it is, is a toast.
      if (e is ServerException && e.code == SdkErrorCode.invalidCredentials) {
        formKey.currentState?.showErrors(
          fieldErrors: {
            ChangePasswordFormFields.currentId:
                AuthViewStrings.currentPasswordIncorrect,
          },
        );
      } else {
        showError(AuthViewStrings.changePasswordFailed);
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (!success || !mounted) return;
    ShadToaster.of(context).show(
      const ShadToast(description: Text(AuthViewStrings.passwordUpdated)),
    );
    widget.onSuccess();
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AuthViewSizes.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AuthViewSizes.padding),
          child: ShadCard(
            padding: const EdgeInsets.all(AuthViewSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AuthViewStrings.changePassword,
                  style: theme.textTheme.h4,
                ),
                const SizedBox(height: AuthViewSizes.cardHeadingGap),
                ChangePasswordForm(key: formKey, enabled: !isSubmitting),
                const SizedBox(height: AuthViewSizes.sectionGap),
                // Wrap (not Row) so the two buttons flow to a second line on
                // narrow surfaces instead of overflowing.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AuthViewSizes.buttonGap,
                  runSpacing: AuthViewSizes.linkGap,
                  children: [
                    ShadButton.outline(
                      onPressed: isSubmitting ? null : widget.onCancel,
                      child: const Text(AuthViewStrings.cancel),
                    ),
                    ShadButton(
                      onPressed: isSubmitting ? null : submit,
                      child: Text(
                        isSubmitting
                            ? AuthViewStrings.saving
                            : AuthViewStrings.updatePassword,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
