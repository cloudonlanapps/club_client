import 'package:cl_club_forms/cl_club_forms.dart' show TwoColumnGrid;
import 'package:cl_club_members/src/widgets/roles_section.dart';
import 'package:cl_club_members/src/widgets/user_management_section.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

/// The admin sections of a profile, side by side: Roles when
/// [onRoleToggle] is given, and User management when [onStatusAction] or
/// [onAdminResetPassword] is.
class ProfileAdminSections extends StatelessWidget {
  /// The admin sections for [user].
  const ProfileAdminSections({
    required this.user,
    required this.isSuperAdmin,
    this.onRoleToggle,
    this.onStatusAction,
    this.onAdminResetPassword,
    super.key,
  });

  /// The member the sections act on.
  final UserPrivate user;

  /// Whether the viewer is a super admin.
  final bool isSuperAdmin;

  /// Called when a role is toggled. If null, Roles is not shown.
  final void Function(Role role, {required bool selected})? onRoleToggle;

  /// Called with the action name ('approve', 'block', etc.).
  final ValueChanged<String>? onStatusAction;

  /// Admin reset password (super admin only).
  final VoidCallback? onAdminResetPassword;

  @override
  Widget build(BuildContext context) {
    return TwoColumnGrid(
      children: [
        if (onRoleToggle != null)
          RolesSection(
            user: user,
            onRoleToggle: onRoleToggle!,
          ),
        if (onStatusAction != null || onAdminResetPassword != null)
          UserManagementSection(
            user: user,
            isSuperAdmin: isSuperAdmin,
            onAdminResetPassword: onAdminResetPassword,
            onStatusAction: onStatusAction,
          ),
      ],
    );
  }
}
