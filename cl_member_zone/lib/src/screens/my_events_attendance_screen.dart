import 'package:cl_club_events/cl_club_events.dart' show MyEventsAttendanceView;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../permissions/my_events_access.dart';

/// My-events attendance screen.
class MyEventsAttendanceScreen extends ConsumerWidget {
  const MyEventsAttendanceScreen({
    required this.targetUsername,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final String targetUsername;
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
    final accessAsync = ref.watch(myEventsAccessProvider(targetUsername));
    return accessAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => _accessDenied(),
      data: (allowed) {
        if (!allowed) return _accessDenied();
        final user = ref.watch(authStateProvider).valueOrNull;
        if (user == null) return _accessDenied();
        final viewingSelf = user.username == targetUsername;
        final displayName = viewingSelf
            ? null
            : (ref
                      .watch(clUsersMasterProvider)
                      .valueOrNull?[targetUsername]
                      ?.displayName ??
                  targetUsername);
        return MyEventsAttendanceView(
          currentUser: user,
          targetUsername: targetUsername,
          viewingSelf: viewingSelf,
          displayName: displayName,
          onHome: onHome,
          onBack: onBack,
        );
      },
    );
  }
}
