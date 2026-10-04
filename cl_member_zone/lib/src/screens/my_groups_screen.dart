import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../permissions/my_groups_access.dart';

/// My-groups screen at `/memberzone/my-groups/:targetUsername`.
///
/// Gates access (self / admin / coach) before mounting [MyGroupsView].
class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({
    required this.targetUsername,
    required this.onHome,
    this.onGroupTap,
    this.onBack,
    super.key,
  });

  final String targetUsername;
  final ValueChanged<int>? onGroupTap;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  Widget _accessDenied() {
    return ErrorView(
      tone: ErrorTone.neutral,
      icon: LucideIcons.shieldAlert,
      title: 'Access Denied',
      subtitle: 'You do not have permission to view this page.',
      onHome: onHome,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(myGroupsAccessProvider(targetUsername));
    return accessAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => _accessDenied(),
      data: (allowed) {
        if (!allowed) return _accessDenied();
        return MyGroupsView(
          username: targetUsername,
          onGroupTap: onGroupTap,
          onBack: onBack,
        );
      },
    );
  }
}
