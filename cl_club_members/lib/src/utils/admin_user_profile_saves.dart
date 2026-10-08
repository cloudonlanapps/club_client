import 'dart:async';

import 'package:cl_club_members/src/widgets/admin_reset_password_result_dialog.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Saves [targetUsername]'s bio or achievements as an admin, and says so
/// in a toast.
Future<void> adminSaveUserField(
  WidgetRef ref,
  BuildContext context,
  String targetUsername, {
  String? Function()? bio,
  String? Function()? achievements,
}) async {
  try {
    await ref
        .read(clUsersMasterProvider.notifier)
        .updateUser(
          targetUsername,
          bio: bio,
          achievements: achievements,
        );
    ref
      ..invalidate(clUserPrivateProvider(targetUsername))
      ..invalidate(authStateProvider);
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      const ShadToast(description: Text('Profile updated.')),
    );
  } on Object catch (_) {
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      const ShadToast.destructive(description: Text('Could not save.')),
    );
  }
}

/// Gives [targetUsername] the [role], or takes it away, and says so in a
/// toast.
Future<void> adminToggleUserRole(
  WidgetRef ref,
  BuildContext context,
  String targetUsername,
  Role role, {
  required bool selected,
}) async {
  try {
    final notifier = ref.read(clUsersMasterProvider.notifier);
    if (selected) {
      await notifier.assignRole(targetUsername, role.name);
    } else {
      await notifier.removeRole(targetUsername, role.name);
    }
    ref.invalidate(clUserPrivateProvider(targetUsername));
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      ShadToast(
        description: Text(
          selected ? 'Added ${role.name} role.' : 'Removed ${role.name} role.',
        ),
      ),
    );
  } on Object catch (_) {
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      const ShadToast.destructive(
        description: Text('Could not update role.'),
      ),
    );
  }
}

/// Applies the lifecycle [action] (`approve`, `block`, …) to
/// [targetUsername], and says so in a toast. An unknown action does nothing.
Future<void> adminApplyUserStatusAction(
  WidgetRef ref,
  BuildContext context,
  String targetUsername,
  String action,
) async {
  try {
    final notifier = ref.read(clUsersMasterProvider.notifier);
    String message;
    switch (action) {
      case 'approve':
        await notifier.approveUser(targetUsername);
        message = 'User approved.';
      case 'block':
        await notifier.blockUser(targetUsername);
        message = 'User blocked.';
      case 'unblock':
        await notifier.unblockUser(targetUsername);
        message = 'User unblocked.';
      case 'markLeft':
        await notifier.markLeft(targetUsername);
        message = 'User marked as left.';
      case 'reactivate':
        await notifier.reactivateUser(targetUsername);
        message = 'User reactivated.';
      case 'restore':
        await notifier.restoreUser(targetUsername);
        message = 'User restored.';
      case 'delete':
        await notifier.deleteUser(targetUsername);
        message = 'User deleted.';
      case 'hardDelete':
        await notifier.hardDeleteUser(targetUsername);
        message = 'User permanently deleted.';
      default:
        return;
    }
    ref.invalidate(clUserPrivateProvider(targetUsername));
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      ShadToast(description: Text(message)),
    );
  } on Object catch (_) {
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      const ShadToast.destructive(description: Text('Action failed.')),
    );
  }
}

/// Resets [targetUsername]'s password and shows the new one in a dialog.
Future<void> adminResetUserPassword(
  WidgetRef ref,
  BuildContext context,
  String targetUsername,
) async {
  try {
    final newPassword = await ref
        .read(clUsersMasterProvider.notifier)
        .adminResetPassword(targetUsername);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminResetPasswordResultDialog(password: newPassword),
    );
  } on Object catch (_) {
    if (!context.mounted) return;
    ShadToaster.of(context).show(
      const ShadToast.destructive(
        description: Text('Could not reset password.'),
      ),
    );
  }
}
