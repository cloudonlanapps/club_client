import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Roles section with Admin / Coach checkbox toggles.
///
/// Matches the create-user screen's role assignment layout — checkbox per
/// role rather than chips. Member is intentionally omitted: membership is
/// derived from approved-user status and is not directly assigned here.
class RolesSection extends StatelessWidget {
  const RolesSection({
    required this.user,
    required this.onRoleToggle,
    super.key,
  });

  final UserPrivate user;
  final void Function(Role role, {required bool selected}) onRoleToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isSuperAdmin = user.isSuperAdmin;
    final mutable = canMutateUser(user);
    final enabled = !isSuperAdmin && mutable;

    final String reason;
    if (isSuperAdmin) {
      reason = 'Super Admin roles cannot be modified.';
    } else if (!mutable) {
      reason = "Roles can't be modified for non-active users.";
    } else {
      reason = 'Toggle the roles assigned to this user.';
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roles', style: theme.textTheme.h4),
          const SizedBox(height: 4),
          Text(
            reason,
            style: enabled
                ? theme.textTheme.muted
                : theme.textTheme.small.copyWith(
                    color: theme.colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: user.roles.isAdmin,
            enabled: enabled,
            onChanged: enabled
                ? (selected) => onRoleToggle(Role.admin, selected: selected)
                : null,
            label: const Text('Make this user an Admin'),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: user.roles.isCoach,
            enabled: enabled,
            onChanged: enabled
                ? (selected) => onRoleToggle(Role.coach, selected: selected)
                : null,
            label: const Text('This user is a coach'),
          ),
        ],
      ),
    );
  }
}
