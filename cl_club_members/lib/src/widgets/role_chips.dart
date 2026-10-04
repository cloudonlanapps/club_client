import 'package:cl_club_members/src/widgets/role_chip.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

/// A row of toggleable chips, one per assignable [Role].
///
/// Super admin is not a role (it is the `isSuperAdmin` flag), so it never
/// appears here.
///
/// Tapping a chip calls [onToggle] with the role and the new desired state.
/// The parent screen is responsible for issuing the SDK call
/// (`assignRole` / `removeRole`) and refreshing state.
///
/// Iterates `Role.values` so the UI does not single out any specific role.
class RoleChips extends StatelessWidget {
  const RoleChips({
    required this.roles,
    required this.onToggle,
    this.enabled = true,
    super.key,
  });

  final UserRoles roles;
  final void Function(Role role, {required bool selected}) onToggle;
  final bool enabled;

  bool _isAssigned(Role role) {
    switch (role) {
      case Role.admin:
        return roles.isAdmin;
      case Role.coach:
        return roles.isCoach;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final role in Role.values)
          RoleChip(
            role: role,
            selected: _isAssigned(role),
            enabled: enabled,
            onToggle: ({required selected}) =>
                onToggle(role, selected: selected),
          ),
      ],
    );
  }
}
