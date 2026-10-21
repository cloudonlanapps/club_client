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
    this.viewerUsername,
    this.onResetPassword,
    this.onAdminResetPassword,
    this.onStatusAction,
    super.key,
  });

  final UserPrivate user;
  final bool isMobile;
  final bool isSuperAdmin;

  /// The signed-in viewer: Block, Mark as Left and Delete are not offered
  /// on their own account.
  final String? viewerUsername;
  final VoidCallback? onResetPassword;
  final VoidCallback? onAdminResetPassword;
  final ValueChanged<String>? onStatusAction;

  @override
  Widget build(BuildContext context) {
    final actions = onStatusAction != null
        ? adminActionsFor(
            user,
            isSuperAdmin: isSuperAdmin,
            viewerUsername: viewerUsername,
          )
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
          enabled: action.isAvailable,
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
