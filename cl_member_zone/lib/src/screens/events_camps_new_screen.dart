import 'package:cl_club_events/cl_club_events.dart' show EventsCampsNewView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, userAllowedForEvents;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

/// New-camp screen at `/memberzone/events/camps/new`.
class EventsCampsNewScreen extends ConsumerWidget {
  const EventsCampsNewScreen({
    required this.onCreated,
    required this.onCancel,
    required this.onHome,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Only coaches/admins may create events; members are denied the route.
    if (!userAllowedForEvents(user) || !(user?.isCoachOrAdmin ?? false)) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to create events.',
        onHome: onHome,
      );
    }
    return EventsCampsNewView(
      currentUser: user!,
      onCreated: onCreated,
      onCancel: onCancel,
    );
  }
}
