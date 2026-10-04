import 'package:cl_club_members/cl_club_members.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../permissions/my_groups_access.dart';

/// My-group details screen at
/// `/memberzone/my-groups/:targetUsername/:groupId`.
///
/// Gates access (self / admin / coach) before mounting [MyGroupDetailsView].
class MyGroupDetailsScreen extends ConsumerWidget {
  const MyGroupDetailsScreen({
    required this.targetUsername,
    required this.groupId,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final String targetUsername;
  final int groupId;
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
        return MyGroupDetailsView(
          username: targetUsername,
          groupId: groupId,
          onBack: onBack,
        );
      },
    );
  }
}
