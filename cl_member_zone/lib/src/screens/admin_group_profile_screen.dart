import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [AdminGroupProfileView] for
/// `/memberzone/groups/:id`.
class AdminGroupProfileScreen extends ConsumerWidget {
  const AdminGroupProfileScreen({
    required this.groupId,
    required this.onOpenRequests,
    required this.onOpenAllMembers,
    required this.onDeleted,
    required this.onHome,
    this.sourceNotificationId,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int groupId;
  final int? sourceNotificationId;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenAllMembers;
  final VoidCallback onDeleted;
  final VoidCallback? onBack;
  final VoidCallback? onHistory;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (_) => AdminGroupProfileView(
        groupId: groupId,
        sourceNotificationId: sourceNotificationId,
        onOpenRequests: onOpenRequests,
        onOpenAllMembers: onOpenAllMembers,
        onDeleted: onDeleted,
        onBack: onBack,
        onHistory: onHistory,
      ),
    );
  }
}
