import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

/// Admin user management screen — thin wrapper around [UserListView].
///
/// Watches `authStateProvider` to resolve the current user, gates on
/// admin/coach role, and forwards `currentUser` to the view. Navigation is
/// supplied by `app/lib/router.dart` as username-keyed callbacks; the screen
/// extracts the username from the tapped user and delegates routing to
/// the host. Delegates all user management UI to `cl_club_members`.
class UsersScreen extends ConsumerWidget {
  const UsersScreen({
    required this.onUserTap,
    required this.onReviewUser,
    required this.onCreateUser,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final void Function(String username) onUserTap;
  final void Function(String username) onReviewUser;
  final VoidCallback onCreateUser;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return const LoadingView(message: 'Loading…');
    }
    if (!currentUser.isCoachOrAdmin) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to view this page.',
        onHome: onHome,
      );
    }
    return UserListView(
      currentUser: currentUser,
      onUserTap: (user) => onUserTap(user.username),
      onReviewUser: (user) => onReviewUser(user.username),
      onCreateUser: onCreateUser,
      onBack: onBack,
      onActNow: () {
        final pending = ref.read(pendingUsersProvider).valueOrNull;
        if (pending == null || pending.isEmpty) return;
        onReviewUser(pending.first.username);
      },
    );
  }
}
