import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [GroupMembersView] for
/// `/memberzone/groups/:id/members`.
class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({
    required this.groupId,
    required this.onRemoved,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final int groupId;

  /// Supplied by the router; called when the group no longer exists.
  final VoidCallback onRemoved;
  final VoidCallback? onBack;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (_) => GroupMembersView(
        groupId: groupId,
        onRemoved: onRemoved,
        onBack: onBack,
      ),
    );
  }
}
