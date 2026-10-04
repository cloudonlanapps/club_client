import 'package:cl_club_members/cl_club_members.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Group;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

/// Screen wrapper around [GroupListView] for `/memberzone/groups`.
///
/// Watches `authStateProvider`, gates on admin/coach role, and
/// forwards `currentUser` to the view.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({
    required this.onGroupTap,
    required this.onCreateGroup,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final void Function(Group group) onGroupTap;
  final VoidCallback onCreateGroup;
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
    return GroupListView(
      currentUser: currentUser,
      onGroupTap: onGroupTap,
      onCreateGroup: onCreateGroup,
      onBack: onBack,
    );
  }
}
