import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show RoleGate;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
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
    this.applicationsSection,
    this.onBack,
    this.onBroadcast,
    this.onHistory,
    this.onOpenReview,
    super.key,
  });

  final String targetUsername;
  final VoidCallback onReview;
  final Widget Function(String username) eventsSection;

  /// Builds the Applications section (club_client#321) for the member and
  /// whether they are the signed-in member.
  final Widget Function(UserPrivate member, {required bool own})?
  applicationsSection;
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
        applicationsSection: applicationsSection,
        onBack: onBack,
        onBroadcast: onBroadcast,
        onHistory: onHistory,
        onOpenReview: onOpenReview,
      ),
    );
  }
}
