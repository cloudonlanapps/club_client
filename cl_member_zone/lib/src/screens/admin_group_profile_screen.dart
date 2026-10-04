import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [AdminGroupProfileView] for
/// `/memberzone/groups/:id`.
class AdminGroupProfileScreen extends StatelessWidget {
  const AdminGroupProfileScreen({
    required this.groupId,
    required this.onOpenRequests,
    required this.onOpenAllMembers,
    required this.onDeleted,
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

  @override
  Widget build(BuildContext context) {
    return AdminGroupProfileView(
      groupId: groupId,
      sourceNotificationId: sourceNotificationId,
      onOpenRequests: onOpenRequests,
      onOpenAllMembers: onOpenAllMembers,
      onDeleted: onDeleted,
      onBack: onBack,
      onHistory: onHistory,
    );
  }
}
