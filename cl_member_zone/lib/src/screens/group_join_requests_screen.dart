import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

/// Screen wrapper around [GroupJoinRequestsView] for
/// `/memberzone/groups/:id/requests`.
///
/// Watches `authStateProvider`, gates on admin/coach role, and
/// forwards `currentUser` to the view.
class GroupJoinRequestsScreen extends ConsumerWidget {
  const GroupJoinRequestsScreen({
    required this.groupId,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final int groupId;
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
    return GroupJoinRequestsView(
      currentUser: currentUser,
      groupId: groupId,
      onBack: onBack,
    );
  }
}
