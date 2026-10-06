import 'dart:async';

import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show UserFormSubmit, buildUserFormInitialValues;
import 'package:cl_club_members/src/utils/admin_user_actions.dart';
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:cl_club_members/src/widgets/pending_join_requests_section.dart';
import 'package:cl_club_members/src/widgets/profile_avatar_area.dart';
import 'package:cl_club_members/src/widgets/profile_credit_line.dart';
import 'package:cl_club_members/src/widgets/profile_review_section.dart';
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:cl_club_members/src/widgets/user_groups_section.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider, clUsersMasterProvider, evaluationsProvider;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ActionButton,
        EditableMarkdown,
        EditableSectionCard,
        LoadingView,
        ReadOnlyField,
        ThemedMarkdown,
        TitleRow,
        TwoColumnGrid,
        UserAddressForm,
        UserAddressFormState,
        UserPersonalDetailsForm,
        UserPersonalDetailsFormState;

/// Admin-aware wrapper around [UserProfileView].
///
/// Reads [authStateProvider] to determine the current user's role and
/// conditionally passes admin-only callbacks. Callers provide only
/// navigation callbacks — authorization is handled internally.
class AdminUserProfileView extends ConsumerWidget {
  const AdminUserProfileView({
    required this.targetUsername,
    this.eventsSection,
    this.onReview,
    this.onBack,
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

  /// Tap handler for the pending-user `Review` action. The host pushes
  /// `AdminUserReviewView` for [targetUsername].
  final VoidCallback? onReview;

  final VoidCallback? onBack;

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
      onBack: onBack,
      onHistory: onHistory,
      onOpenReview: onOpenReview,
      onBioSave: isAdmin
          ? (bio) => handleFieldSave(ref, context, bio: () => bio)
          : null,
      onAchievementsSave: isAdmin
          ? (achievements) =>
                handleFieldSave(ref, context, achievements: () => achievements)
          : null,
      onRoleToggle: isAdmin
          ? (role, {required selected}) =>
                handleRoleToggle(ref, context, role, selected: selected)
          : null,
      onStatusAction: isAdmin
          ? (action) {
              if (action == 'review') {
                onReview?.call();
                return;
              }
              unawaited(handleStatusAction(ref, context, action));
            }
          : null,
      onAdminResetPassword: isSuperAdmin
          ? () => handleAdminResetPassword(ref, context)
          : null,
    );
  }

  Future<void> handleFieldSave(
    WidgetRef ref,
    BuildContext context, {
    String? Function()? bio,
    String? Function()? achievements,
  }) async {
    try {
      await ref
          .read(clUsersMasterProvider.notifier)
          .updateUser(
            targetUsername,
            bio: bio,
            achievements: achievements,
          );
      ref
        ..invalidate(clUserPrivateProvider(targetUsername))
        ..invalidate(authStateProvider);
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Profile updated.')),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(description: Text('Could not save.')),
      );
    }
  }

  Future<void> handleRoleToggle(
    WidgetRef ref,
    BuildContext context,
    Role role, {
    required bool selected,
  }) async {
    try {
      final notifier = ref.read(clUsersMasterProvider.notifier);
      if (selected) {
        await notifier.assignRole(targetUsername, role.name);
      } else {
        await notifier.removeRole(targetUsername, role.name);
      }
      ref.invalidate(clUserPrivateProvider(targetUsername));
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(
            selected
                ? 'Added ${role.name} role.'
                : 'Removed ${role.name} role.',
          ),
        ),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update role.'),
        ),
      );
    }
  }

  Future<void> handleStatusAction(
    WidgetRef ref,
    BuildContext context,
    String action,
  ) async {
    try {
      final notifier = ref.read(clUsersMasterProvider.notifier);
      String message;
      switch (action) {
        case 'approve':
          await notifier.approveUser(targetUsername);
          message = 'User approved.';
        case 'block':
          await notifier.blockUser(targetUsername);
          message = 'User blocked.';
        case 'unblock':
          await notifier.unblockUser(targetUsername);
          message = 'User unblocked.';
        case 'markLeft':
          await notifier.markLeft(targetUsername);
          message = 'User marked as left.';
        case 'reactivate':
          await notifier.reactivateUser(targetUsername);
          message = 'User reactivated.';
        case 'restore':
          await notifier.restoreUser(targetUsername);
          message = 'User restored.';
        case 'delete':
          await notifier.deleteUser(targetUsername);
          message = 'User deleted.';
        case 'hardDelete':
          await notifier.hardDeleteUser(targetUsername);
          message = 'User permanently deleted.';
        default:
          return;
      }
      ref.invalidate(clUserPrivateProvider(targetUsername));
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast(description: Text(message)),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(description: Text('Action failed.')),
      );
    }
  }

  Future<void> handleAdminResetPassword(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      final newPassword = await ref
          .read(clUsersMasterProvider.notifier)
          .adminResetPassword(targetUsername);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AdminResetPasswordResultDialog(password: newPassword),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not reset password.'),
        ),
      );
    }
  }
}

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
          final theme = ShadTheme.of(context);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.userX,
                  size: 48,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(height: 12),
                Text('Profile Unavailable', style: theme.textTheme.h4),
                const SizedBox(height: 4),
                Text(
                  'This user profile is not available.',
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          );
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
                      TwoColumnGrid(
                        children: [
                          if (onRoleToggle != null)
                            RolesSection(
                              user: user,
                              onRoleToggle: onRoleToggle!,
                            ),
                          if (onStatusAction != null ||
                              onAdminResetPassword != null)
                            UserManagementSection(
                              user: user,
                              isSuperAdmin: viewerIsSuperAdmin,
                              onAdminResetPassword: onAdminResetPassword,
                              onStatusAction: onStatusAction,
                            ),
                        ],
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

/// Main profile card — mirrors CoachCard layout.
///
/// Desktop: avatar image on the left, content on the right.
/// Mobile: avatar image on top, content below.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({
    required this.user,
    required this.isMobile,
    this.onBioSave,
    this.onAchievementsSave,
    super.key,
  });

  final UserInfo user;
  final bool isMobile;

  /// Called with updated bio markdown. If null, bio is not editable.
  final ValueChanged<String>? onBioSave;

  /// Called with updated achievements markdown. If null, achievements is not
  /// editable.
  final ValueChanged<String>? onAchievementsSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final avatarWidget = ProfileAvatarArea(user: user);
    final contentWidget = ProfileContentArea(
      user: user,
      onBioSave: onBioSave,
      onAchievementsSave: onAchievementsSave,
    );

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: avatarWidget,
                ),
              ),
            ),
            contentWidget,
          ],
        ),
      );
    }

    // Desktop: image on the left, content on the right.
    //
    // IntrinsicHeight forces the Row to size to the taller child's height,
    // and CrossAxisAlignment.stretch then makes the avatar column take that
    // full height. UserAvatar is built to fill its parent, so it scales the
    // image with BoxFit.cover.
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 260, child: avatarWidget),
            Expanded(child: contentWidget),
          ],
        ),
      ),
    );
  }
}

/// Content area: name, status, roles, bio, achievements.
class ProfileContentArea extends ConsumerWidget {
  const ProfileContentArea({
    required this.user,
    this.onBioSave,
    this.onAchievementsSave,
    super.key,
  });

  final UserInfo user;

  /// Called with updated bio markdown. If null, bio is not editable.
  final ValueChanged<String>? onBioSave;

  /// Called with updated achievements markdown. If null, achievements is not
  /// editable.
  final ValueChanged<String>? onAchievementsSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role stamps overlay the avatar (see ProfileRoleStamps).
          // Name / username live in Contact & Details below; where credit
          // is on, the name leads the card with the member's credit.
          ProfileCreditLine(user: user),
          // Bio
          if (onBioSave != null) ...[
            EditableMarkdown(
              data: user.bio ?? '',
              label: 'Bio',
              emptyText: 'Tap to add bio',
              onSave: onBioSave!,
            ),
            const SizedBox(height: 24),
          ] else if (user.bio != null && user.bio!.isNotEmpty) ...[
            ThemedMarkdown(data: user.bio!, textAlign: TextAlign.justify),
            const SizedBox(height: 24),
          ],
          // Achievements
          if (onAchievementsSave != null) ...[
            Text('Achievements', style: theme.textTheme.h4),
            const SizedBox(height: 8),
            EditableMarkdown(
              data: user.achievements ?? '',
              label: 'Achievements',
              emptyText: 'Tap to add achievements',
              onSave: onAchievementsSave!,
            ),
          ] else if (user.achievements != null &&
              user.achievements!.isNotEmpty) ...[
            Text('Achievements', style: theme.textTheme.h4),
            const SizedBox(height: 8),
            ThemedMarkdown(
              data: user.achievements!,
              textAlign: TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }
}

// ── User-profile section editors ───────────────────────────────────────────
// Each section edits in place (see [EditableSectionCard]). Shared by the admin
// profile and the self profile. Date of birth and gender are editable only by
// a super-admin; the form gates them and the partial update omits keys it
// wasn't allowed to change.

/// Personal-details profile section — name, date of birth, gender. Edits in
/// place; date of birth / gender / public-name flag are editable only by a
/// super-admin.
class PersonalDetailsCard extends ConsumerStatefulWidget {
  const PersonalDetailsCard({
    required this.user,
    required this.canEdit,
    super.key,
  });

  final UserPrivate user;
  final bool canEdit;

  @override
  ConsumerState<PersonalDetailsCard> createState() =>
      _PersonalDetailsCardState();
}

class _PersonalDetailsCardState extends ConsumerState<PersonalDetailsCard> {
  final _formKey = GlobalKey<UserPersonalDetailsFormState>();

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = viewer?.isSuperAdmin ?? false;
    // Public-profile visibility is the coach's own to set: only when the
    // viewer is this user and they hold the coach role. Admins can't override.
    final canEditPublicProfile =
        viewer != null &&
        viewer.username == user.username &&
        user.roles.isCoach;
    final rows = <Widget?>[
      profileDetailRow(context, LucideIcons.idCard, 'Name', user.displayName),
      if (user.dateOfBirthUtc != null)
        profileDetailRow(
          context,
          LucideIcons.cake,
          'Date of Birth',
          user.dateOfBirthUtc!.toLocalDateMedium(),
        ),
      if (user.gender != null)
        profileDetailRow(
          context,
          LucideIcons.user,
          'Gender',
          user.gender!.label,
        ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Personal details',
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: 'Tap to add personal details',
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: () => UserPersonalDetailsForm(
        key: _formKey,
        initialValues: buildUserFormInitialValues(user),
        canEditDateOfBirth: isSuperAdmin,
        canEditGender: isSuperAdmin,
        canEditUseNamePublicly: isSuperAdmin,
        canEditPublicProfile: canEditPublicProfile,
      ),
      onValidate: () => _formKey.currentState?.validate(),
      isDirty: () => _formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserFormSubmit.updatePersonalDetails(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: 'Personal details updated.',
      ),
    );
  }
}

/// Address profile section. Edits in place.
class AddressCard extends ConsumerStatefulWidget {
  const AddressCard({required this.user, required this.canEdit, super.key});

  final UserPrivate user;
  final bool canEdit;

  @override
  ConsumerState<AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends ConsumerState<AddressCard> {
  final _formKey = GlobalKey<UserAddressFormState>();

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final addr = user.address;
    final rows = <Widget?>[
      if (addr != null && !addr.isEmpty)
        profileDetailRow(
          context,
          LucideIcons.mapPin,
          'Address',
          _formatAddress(addr),
        ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Address',
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: 'Tap to add address',
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: () => UserAddressForm(
        key: _formKey,
        initialValues: buildUserFormInitialValues(user),
      ),
      onValidate: () => _formKey.currentState?.validate(),
      isDirty: () => _formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserFormSubmit.updateAddress(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: 'Address updated.',
      ),
    );
  }
}

String _formatAddress(Address addr) {
  return [
    addr.addrLine1,
    addr.addrLine2,
    addr.city,
    addr.state,
    addr.pincode,
  ].where((s) => s != null && s.isNotEmpty).join(', ');
}

/// Placeholder section for Events (SDK not ready).
class EventsPlaceholderSection extends StatelessWidget {
  const EventsPlaceholderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Events', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text('Coming soon', style: theme.textTheme.muted),
            ],
          ),
        ],
      ),
    );
  }
}

/// Roles section with Admin / Coach checkbox toggles.
///
/// Matches the create-user screen's role assignment layout — checkbox per
/// role rather than chips. Member is intentionally omitted: membership is
/// derived from approved-user status and is not directly assigned here.
class RolesSection extends StatelessWidget {
  const RolesSection({
    required this.user,
    required this.onRoleToggle,
    super.key,
  });

  final UserPrivate user;
  final void Function(Role role, {required bool selected}) onRoleToggle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isSuperAdmin = user.isSuperAdmin;
    final mutable = canMutateUser(user);
    final enabled = !isSuperAdmin && mutable;

    final String reason;
    if (isSuperAdmin) {
      reason = 'Super Admin roles cannot be modified.';
    } else if (!mutable) {
      reason = "Roles can't be modified for non-active users.";
    } else {
      reason = 'Toggle the roles assigned to this user.';
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roles', style: theme.textTheme.h4),
          const SizedBox(height: 4),
          Text(
            reason,
            style: enabled
                ? theme.textTheme.muted
                : theme.textTheme.small.copyWith(
                    color: theme.colorScheme.primary,
                  ),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: user.roles.isAdmin,
            enabled: enabled,
            onChanged: enabled
                ? (selected) => onRoleToggle(Role.admin, selected: selected)
                : null,
            label: const Text('Make this user an Admin'),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: user.roles.isCoach,
            enabled: enabled,
            onChanged: enabled
                ? (selected) => onRoleToggle(Role.coach, selected: selected)
                : null,
            label: const Text('This user is a coach'),
          ),
        ],
      ),
    );
  }
}

/// 2×2 grid of admin user-management actions.
///
/// The set of lifecycle buttons (Approve / Block / Unblock / Mark as Left /
/// Reactivate / Restore / Delete / Hard Delete) is driven by the target
/// user's status via [adminActionsFor]. Surfaced alongside [RolesSection]
/// on the admin user profile. Self-view uses [ProfileActionsSection].
class UserManagementSection extends StatelessWidget {
  const UserManagementSection({
    required this.user,
    required this.isSuperAdmin,
    this.onAdminResetPassword,
    this.onStatusAction,
    super.key,
  });

  final UserPrivate user;
  final bool isSuperAdmin;
  final VoidCallback? onAdminResetPassword;
  final ValueChanged<String>? onStatusAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final actions = onStatusAction != null
        ? adminActionsFor(user, isSuperAdmin: isSuperAdmin)
        : const <UserAdminAction>[];
    final buttons = <Widget>[
      if (onAdminResetPassword != null)
        ActionButton(
          label: 'Reset Password',
          onPressed: onAdminResetPassword,
        ),
      for (final action in actions)
        ActionButton(
          label: action.label,
          onPressed: () => onStatusAction!(action.key),
        ),
    ];
    while (buttons.length < 4) {
      buttons.add(
        const IgnorePointer(
          child: Opacity(
            opacity: 0,
            child: ActionButton(label: ''),
          ),
        ),
      );
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Management', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          TwoColumnGrid(
            spacing: 8,
            runSpacing: 8,
            singleColumnBreakpoint: 0,
            children: buttons,
          ),
        ],
      ),
    );
  }
}

/// Action buttons: Change Password plus the lifecycle actions allowed for
/// the user's current status. Desktop: buttons in a row. Mobile: stacked.
class ProfileActionsSection extends StatelessWidget {
  const ProfileActionsSection({
    required this.user,
    required this.isMobile,
    required this.isSuperAdmin,
    this.onResetPassword,
    this.onAdminResetPassword,
    this.onStatusAction,
    super.key,
  });

  final UserPrivate user;
  final bool isMobile;
  final bool isSuperAdmin;
  final VoidCallback? onResetPassword;
  final VoidCallback? onAdminResetPassword;
  final ValueChanged<String>? onStatusAction;

  @override
  Widget build(BuildContext context) {
    final actions = onStatusAction != null
        ? adminActionsFor(user, isSuperAdmin: isSuperAdmin)
        : const <UserAdminAction>[];
    final buttons = <Widget>[
      if (onResetPassword != null)
        ActionButton(
          label: 'Change Password',
          onPressed: onResetPassword,
        )
      else if (onAdminResetPassword != null)
        ActionButton(
          label: 'Reset Password',
          onPressed: onAdminResetPassword,
        ),
      for (final action in actions)
        ActionButton(
          label: action.label,
          onPressed: () => onStatusAction!(action.key),
        ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            buttons[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          buttons[i],
        ],
      ],
    );
  }
}

/// Account info section showing member since and last login.
class AccountInfoSection extends StatelessWidget {
  const AccountInfoSection({required this.user, super.key});

  final UserPrivate user;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Info', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          ReadOnlyField(
            label: 'Member since',
            value: DateFormat(
              'd MMM yyyy, HH:mm',
            ).format(user.createdAtUtc.toLocal()),
          ),
          const SizedBox(height: 8),
          ReadOnlyField(
            label: 'Last login',
            value: user.lastLoginAtUtc != null
                ? DateFormat(
                    'd MMM yyyy, HH:mm',
                  ).format(user.lastLoginAtUtc!.toLocal())
                : 'Never',
          ),
        ],
      ),
    );
  }
}

/// Dialog showing a server-generated password with Copy and OK buttons.
class AdminResetPasswordResultDialog extends StatelessWidget {
  const AdminResetPasswordResultDialog({
    required this.password,
    super.key,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return AlertDialog(
      title: const Text('Password Reset'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New temporary password:',
              style: theme.textTheme.small,
            ),
            const SizedBox(height: 8),
            SelectableText(
              password,
              style: theme.textTheme.large.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: password));
            if (!context.mounted) return;
            ShadToaster.of(context).show(
              const ShadToast(description: Text('Copied to clipboard.')),
            );
          },
          icon: const Icon(LucideIcons.copy, size: 16),
          label: const Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
