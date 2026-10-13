import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton;

/// Action buttons: Change Password plus the lifecycle actions allowed for
/// the user's current status. Desktop: buttons in a row. Mobile: stacked.
class ProfileActionsSection extends StatelessWidget {
  const ProfileActionsSection({
    required this.user,
    required this.isMobile,
    required this.isSuperAdmin,
    this.onResetPassword,
    this.onAdminResetPassword,
    this.onStatusAction,
    super.key,
  });

  final UserPrivate user;
  final bool isMobile;
  final bool isSuperAdmin;
  final VoidCallback? onResetPassword;
  final VoidCallback? onAdminResetPassword;
  final ValueChanged<String>? onStatusAction;

  @override
  Widget build(BuildContext context) {
    final actions = onStatusAction != null
        ? adminActionsFor(user, isSuperAdmin: isSuperAdmin)
        : const <UserAdminAction>[];
    final buttons = <Widget>[
      if (onResetPassword != null)
        ActionButton(
          label: 'Change Password',
          onPressed: onResetPassword,
        )
      else if (onAdminResetPassword != null)
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

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            buttons[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          buttons[i],
        ],
      ],
    );
  }
}
