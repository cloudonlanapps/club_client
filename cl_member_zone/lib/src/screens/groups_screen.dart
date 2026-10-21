import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:club_sdk_2/club_sdk_2.dart' show Group;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen wrapper around [GroupListView] for `/memberzone/groups`.
///
/// Watches `authStateProvider`, gates on admin/coach role, and
/// forwards `currentUser` to the view.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({
    required this.onGroupTap,
    required this.onCreateGroup,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final void Function(Group group) onGroupTap;
  final VoidCallback onCreateGroup;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (currentUser) {
        return GroupListView(
          currentUser: currentUser,
          onGroupTap: onGroupTap,
          onCreateGroup: onCreateGroup,
          onBack: onBack,
        );
      },
    );
  }
}
