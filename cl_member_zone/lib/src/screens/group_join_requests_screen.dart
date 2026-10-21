import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen wrapper around [GroupJoinRequestsView] for
/// `/memberzone/groups/:id/requests`.
///
/// Watches `authStateProvider`, gates on admin/coach role, and
/// forwards `currentUser` to the view.
class GroupJoinRequestsScreen extends ConsumerWidget {
  const GroupJoinRequestsScreen({
    required this.groupId,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final int groupId;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (currentUser) {
        return GroupJoinRequestsView(
          currentUser: currentUser,
          groupId: groupId,
          onBack: onBack,
        );
      },
    );
  }
}
