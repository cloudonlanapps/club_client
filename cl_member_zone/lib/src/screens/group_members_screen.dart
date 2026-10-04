import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [GroupMembersView] for
/// `/memberzone/groups/:id/members`.
class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({
    required this.groupId,
    required this.onRemoved,
    this.onBack,
    super.key,
  });

  final int groupId;

  /// Supplied by the router; called when the group no longer exists.
  final VoidCallback onRemoved;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GroupMembersView(
      groupId: groupId,
      onRemoved: onRemoved,
      onBack: onBack,
    );
  }
}
