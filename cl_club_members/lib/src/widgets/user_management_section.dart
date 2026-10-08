import 'package:cl_club_forms/cl_club_forms.dart' show TwoColumnGrid;
import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

/// 2×2 grid of admin user-management actions.
///
/// The set of lifecycle buttons (Approve / Block / Unblock / Mark as Left /
/// Reactivate / Restore / Delete / Hard Delete) is driven by the target
/// user's status via [adminActionsFor]. Surfaced alongside `RolesSection`
/// on the admin user profile. Self-view uses `ProfileActionsSection`.
class UserManagementSection extends StatelessWidget {
  const UserManagementSection({
    required this.user,
    required this.isSuperAdmin,
    this.onAdminResetPassword,
    this.onStatusAction,
    super.key,
  });

  final UserPrivate user;
  final bool isSuperAdmin;
  final VoidCallback? onAdminResetPassword;
  final ValueChanged<String>? onStatusAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final actions = onStatusAction != null
        ? adminActionsFor(user, isSuperAdmin: isSuperAdmin)
        : const <UserAdminAction>[];
    final buttons = <Widget>[
      if (onAdminResetPassword != null)
        ActionButton(
          label: 'Reset Password',
          onPressed: onAdminResetPassword,
        ),
      for (final action in actions)
        ActionButton(
          label: action.label,
          onPressed: () => onStatusAction!(action.key),
        ),
    ];
    while (buttons.length < 4) {
      buttons.add(
        const IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: ActionButton(label: ''),
          ),
        ),
      );
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          TwoColumnGrid(
            spacing: 8,
            runSpacing: 8,
            singleColumnBreakpoint: 0,
            children: buttons,
          ),
        ],
      ),
    );
  }
}
