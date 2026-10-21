import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin screen wrapper around [AdminUserProfileView] for
/// `/memberzone/users/:targetUsername`.
class AdminUserProfileScreen extends ConsumerWidget {
  const AdminUserProfileScreen({
    required this.targetUsername,
    required this.onReview,
    required this.eventsSection,
    required this.onHome,
    this.onBack,
    this.onBroadcast,
    this.onHistory,
    this.onOpenReview,
    super.key,
  });

  final String targetUsername;
  final VoidCallback onReview;
  final Widget Function(String username) eventsSection;
  final VoidCallback? onBack;

  /// Opens the Broadcast screen for this page's audience (club_client#252).
  final VoidCallback? onBroadcast;
  final VoidCallback? onHistory;

  /// Opens an evaluation a coach started from the profile (club_core#174).
  final ValueChanged<int>? onOpenReview;

  /// Goes to the dashboard from a refusal. Supplied by the router.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: RoleGate.coachOrAdmin,
      onHome: onHome,
      builder: (_) => AdminUserProfileView(
        targetUsername: targetUsername,
        onReview: onReview,
        eventsSection: eventsSection,
        onBack: onBack,
        onBroadcast: onBroadcast,
        onHistory: onHistory,
        onOpenReview: onOpenReview,
      ),
    );
  }
}
