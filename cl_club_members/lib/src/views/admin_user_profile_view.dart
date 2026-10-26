import 'dart:async';

import 'package:cl_club_members/src/utils/admin_user_profile_saves.dart';
import 'package:cl_club_members/src/views/user_profile_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin-aware wrapper around [UserProfileView].
///
/// Reads [authStateProvider] to determine the current user's role and
/// conditionally passes admin-only callbacks. Callers provide only
/// navigation callbacks — authorization is handled internally.
class AdminUserProfileView extends ConsumerWidget {
  const AdminUserProfileView({
    required this.targetUsername,
    this.eventsSection,
    this.applicationsSection,
    this.onReview,
    this.onBack,
    this.onBroadcast,
    this.onHistory,
    this.onOpenReview,
    super.key,
  });

  /// The user being viewed, taken from the route's `:targetUsername` path
  /// parameter. May differ from the logged-in user.
  final String targetUsername;

  /// Optional builder for the events section. Receives the username so the
  /// host app can construct the section without knowing the username upfront.
  final Widget Function(String username)? eventsSection;

  /// Optional builder of the Applications section (club_client#321), given
  /// the member and whether they are the signed-in member. Shown to the
  /// member and to admins. Injected to avoid a direct dependency on
  /// cl_club_applications.
  final Widget Function(UserPrivate member, {required bool own})?
  applicationsSection;

  /// Tap handler for the pending-user `Review` action. The host pushes
  /// `AdminUserReviewView` for [targetUsername].
  final VoidCallback? onReview;

  final VoidCallback? onBack;

  /// Opens the one-to-one Broadcast screen for this user (admin-only
  /// affordance, club_client#252).
  final VoidCallback? onBroadcast;

  /// Opens this user's audit history (admin-only affordance, issue #207).
  final VoidCallback? onHistory;

  /// Opens an evaluation a coach just started from this profile
  /// (club_core#174).
  final ValueChanged<int>? onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = auth?.isSuperAdmin ?? false;
    final isAdmin = auth?.isAdmin ?? false;

    return UserProfileView(
      targetUsername: targetUsername,
      eventsSection: eventsSection,
      applicationsSection: applicationsSection,
      onBack: onBack,
      onBroadcast: onBroadcast,
      onHistory: onHistory,
      onOpenReview: onOpenReview,
      onBioSave: isAdmin
          ? (bio) =>
                adminSaveUserField(ref, context, targetUsername, bio: () => bio)
          : null,
      onAchievementsSave: isAdmin
          ? (achievements) => adminSaveUserField(
              ref,
              context,
              targetUsername,
              achievements: () => achievements,
            )
          : null,
      onRoleToggle: isAdmin
          ? (role, {required selected}) => adminToggleUserRole(
              ref,
              context,
              targetUsername,
              role,
              selected: selected,
            )
          : null,
      onStatusAction: isAdmin
          ? (action) {
              if (action == 'review') {
                onReview?.call();
                return;
              }
              unawaited(
                adminApplyUserStatusAction(
                  ref,
                  context,
                  targetUsername,
                  action,
                ),
              );
            }
          : null,
      onAdminResetPassword: isSuperAdmin
          ? () => adminResetUserPassword(ref, context, targetUsername)
          : null,
    );
  }
}
