import 'package:cl_club_members/src/widgets/role_chips.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Card section showing the user's roles with toggleable chips.
class AdminRolesCard extends StatelessWidget {
  const AdminRolesCard({
    required this.user,
    required this.isSubmitting,
    required this.onToggle,
    super.key,
  });

  final UserPrivate user;
  final bool isSubmitting;
  final void Function(Role role, {required bool selected}) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roles', style: theme.textTheme.h4),
          const SizedBox(height: 8),
          Text(
            'Tap a chip to toggle the role for this user.',
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 12),
          RoleChips(
            roles: user.roles,
            enabled: !isSubmitting,
            onToggle: onToggle,
          ),
          if (user.isSuperAdmin) ...[
            const SizedBox(height: 12),
            Text(
              'This user is the Super Admin.',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
