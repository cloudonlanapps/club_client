import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';

/// Thin screen wrapper around [AdminUserProfileView] for
/// `/memberzone/users/:targetUsername`.
class AdminUserProfileScreen extends StatelessWidget {
  const AdminUserProfileScreen({
    required this.targetUsername,
    required this.onReview,
    required this.eventsSection,
    this.onBack,
    this.onHistory,
    this.onOpenReview,
    super.key,
  });

  final String targetUsername;
  final VoidCallback onReview;
  final Widget Function(String username) eventsSection;
  final VoidCallback? onBack;
  final VoidCallback? onHistory;

  /// Opens an evaluation a coach started from the profile (club_core#174).
  final ValueChanged<int>? onOpenReview;

  @override
  Widget build(BuildContext context) {
    return AdminUserProfileView(
      targetUsername: targetUsername,
      onReview: onReview,
      eventsSection: eventsSection,
      onBack: onBack,
      onHistory: onHistory,
      onOpenReview: onOpenReview,
    );
  }
}
