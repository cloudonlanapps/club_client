import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ChangePasswordForm;

import '../providers/auth.dart';

/// Connected self-service "change my password" view — no Scaffold.
///
/// Wraps the SDK-free [ChangePasswordForm] and wires it to
/// [authStateProvider], translating server errors to messages. Can be used in
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

class ChangePasswordViewState extends ConsumerState<ChangePasswordView> {
  bool isSubmitting = false;

  Future<void> _handleSubmit(String current, String next) async {
    setState(() => isSubmitting = true);
    var success = false;
    try {
      if (widget.onChangePassword != null) {
        await widget.onChangePassword!(
          currentPassword: current,
          newPassword: next,
        );
      } else {
        await ref
            .read(authStateProvider.notifier)
            .changePassword(currentPassword: current, newPassword: next);
      }
      success = true;
    } on ServerException catch (e) {
      if (e.code == SdkErrorCode.invalidCredentials) {
        _showError('Current password is incorrect');
      } else {
        _showError('Could not change password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (!success || !mounted) return;
    ShadToaster.of(context).show(
      const ShadToast(description: Text('Password updated.')),
    );
    widget.onSuccess();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangePasswordForm(
      isSubmitting: isSubmitting,
      onSubmit: _handleSubmit,
      onCancel: widget.onCancel,
    );
  }
}
