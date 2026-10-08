import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:cl_club_members/src/widgets/account_info_section.dart';
import 'package:cl_club_members/src/widgets/address_card.dart';
import 'package:cl_club_members/src/widgets/events_placeholder_section.dart';
import 'package:cl_club_members/src/widgets/pending_join_requests_section.dart';
import 'package:cl_club_members/src/widgets/personal_details_card.dart';
import 'package:cl_club_members/src/widgets/profile_actions_section.dart';
import 'package:cl_club_members/src/widgets/profile_admin_sections.dart';
import 'package:cl_club_members/src/widgets/profile_card.dart';
import 'package:cl_club_members/src/widgets/profile_review_section.dart';
import 'package:cl_club_members/src/widgets/profile_unavailable.dart';
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:cl_club_members/src/widgets/user_groups_section.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView, TitleRow;

/// Read-only profile view for viewing any user's profile.
///
/// Mirrors the CoachCard design: responsive layout with a large avatar area,
/// prominent name, and bio/achievements rendered as markdown.
/// No Scaffold — the host provides the shell.
class UserProfileView extends ConsumerWidget {
  const UserProfileView({
    required this.targetUsername,
    this.eventsSection,
    this.onBioSave,
    this.onAchievementsSave,
    this.onRoleToggle,
    this.onStatusAction,
    this.onResetPassword,
    this.onAdminResetPassword,
    this.onBack,
    this.onHistory,
    this.onOpenReview,
    super.key,
  });

  /// The user whose profile is being viewed. May differ from the
  /// logged-in user.
  final String targetUsername;

  /// Optional builder for the events section. Receives the username so the
  /// host app can construct the section without knowing the username upfront.
  /// Injected to avoid a direct dependency on cl_club_events.
  final Widget Function(String username)? eventsSection;

  /// Called with updated bio markdown. If null, bio is not editable.
  final ValueChanged<String>? onBioSave;

  /// Called with updated achievements markdown. If null, achievements is not
  /// editable.
  final ValueChanged<String>? onAchievementsSave;

  /// Called when a role is toggled. If null, Roles section is hidden.
  final void Function(Role role, {required bool selected})? onRoleToggle;

  /// Called with the action name ('approve', 'block', etc.).
  /// If null, Status actions section is hidden.
  final ValueChanged<String>? onStatusAction;

  /// Opens the self-service change-password UI. The consumer chooses how
  /// to render the form (dialog, route, etc.). If null, the Change Password
  /// button is hidden.
  final VoidCallback? onResetPassword;

  /// Admin reset password (super admin only). If provided, shows a
  /// Reset Password button that calls the server to generate a new password.
  final VoidCallback? onAdminResetPassword;

  final VoidCallback? onBack;

  /// Opens this user's audit history. The title-row affordance is shown only
  /// to admin viewers (issue #207).
  final VoidCallback? onHistory;

  /// Opens an evaluation a coach just started with **Add Review**
  /// (club_core#174). The section shows only to a coach viewing another
  /// active member while evaluations are on.
  final ValueChanged<int>? onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(clUserPrivateProvider(targetUsername));
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final viewerIsAdmin = viewer?.isAdmin ?? false;
    final viewerIsSuperAdmin = viewer?.isSuperAdmin ?? false;
    final evaluations = ref.watch(evaluationsProvider) ?? false;

    return detail.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('Could not load user: $e')),
      data: (user) {
        if (!viewerIsAdmin && user.status != UserStatus.active) {
          return const ProfileUnavailable();
        }
        final isMobile = MediaQuery.sizeOf(context).width < 700;
        final mutable = canMutateUser(user);
        final effectiveBioSave = mutable ? onBioSave : null;
        final effectiveAchievementsSave = mutable ? onAchievementsSave : null;
        // A section is editable when the viewer is an admin acting on a
        // mutable user, or the viewer is editing their own profile.
        final isSelf = viewer != null && viewer.username == user.username;
        final canEdit = mutable && (viewerIsAdmin || isSelf);
        final reviewer = evaluations && viewer != null && viewer.roles.isCoach
            ? viewer
            : null;
        final canAddReview =
            reviewer != null && !isSelf && user.status == UserStatus.active;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleRow(
              title: user.displayName.trim().isNotEmpty
                  ? 'Profile — ${user.displayName}'
                  : 'Profile',
              onBack: onBack,
              onHistory: viewerIsAdmin ? onHistory : null,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileCard(
                      user: user,
                      isMobile: isMobile,
                      onBioSave: effectiveBioSave,
                      onAchievementsSave: effectiveAchievementsSave,
                    ),
                    const SizedBox(height: 20),
                    PersonalDetailsCard(user: user, canEdit: canEdit),
                    const SizedBox(height: 20),
                    UserContactInfoCard(user: user, canEdit: canEdit),
                    const SizedBox(height: 20),
                    AddressCard(user: user, canEdit: canEdit),
                    const SizedBox(height: 20),
                    UserGroupsSection(username: targetUsername),
                    PendingJoinRequestsSection(username: targetUsername),
                    const SizedBox(height: 20),
                    if (eventsSection != null)
                      eventsSection!(targetUsername)
                    else
                      const EventsPlaceholderSection(),
                    if (canAddReview) ...[
                      const SizedBox(height: 20),
                      ProfileReviewSection(
                        coach: reviewer,
                        username: targetUsername,
                        onOpenReview: onOpenReview,
                      ),
                    ],
                    if (onRoleToggle != null ||
                        onStatusAction != null ||
                        onAdminResetPassword != null) ...[
                      const SizedBox(height: 20),
                      ProfileAdminSections(
                        user: user,
                        isSuperAdmin: viewerIsSuperAdmin,
                        onRoleToggle: onRoleToggle,
                        onStatusAction: onStatusAction,
                        onAdminResetPassword: onAdminResetPassword,
                      ),
                    ],
                    const SizedBox(height: 20),
                    AccountInfoSection(user: user),
                    if (onRoleToggle == null && onResetPassword != null) ...[
                      const SizedBox(height: 20),
                      ProfileActionsSection(
                        user: user,
                        isMobile: isMobile,
                        isSuperAdmin: viewerIsSuperAdmin,
                        onResetPassword: onResetPassword,
                        onAdminResetPassword: onAdminResetPassword,
                        onStatusAction: onStatusAction,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
