import 'package:cl_club_members/src/views/user_profile_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show ChangePasswordView, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUserPrivateProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Self-profile view that delegates to [UserProfileView] for the
/// supplied [currentUser].
///
/// The wrapping screen (`ProfileScreen` in `cl_member_zone`) resolves
/// the current user from auth and forwards it here. Editing happens
/// section-by-section in place. No Scaffold — the host provides the shell.
class ProfileView extends ConsumerWidget {
  const ProfileView({
    required this.currentUser,
    this.eventsSection,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;

  /// Optional builder for the events section. Receives the username so the
  /// host app can construct the section without knowing the username upfront.
  final Widget Function(String username)? eventsSection;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = currentUser.username;
    return UserProfileView(
      targetUsername: username,
      eventsSection: eventsSection,
      onBack: onBack,
      onBioSave: (bio) =>
          _handleFieldSave(ref, context, username, bio: () => bio),
      onAchievementsSave: (achievements) => _handleFieldSave(
        ref,
        context,
        username,
        achievements: () => achievements,
      ),
      onResetPassword: () => _showChangePasswordDialog(context),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ChangePasswordView(
          onSuccess: () => Navigator.of(dialogContext).pop(),
          onCancel: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<void> _handleFieldSave(
    WidgetRef ref,
    BuildContext context,
    String username, {
    String? Function()? bio,
    String? Function()? achievements,
  }) async {
    try {
      await ref
          .read(clUsersMasterProvider.notifier)
          .updateUser(
            username,
            bio: bio,
            achievements: achievements,
          );
      ref
        ..invalidate(clUserPrivateProvider(username))
        ..invalidate(authStateProvider);
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Profile updated.')),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not save.'),
        ),
      );
    }
  }
}
