import 'package:cl_club_events/cl_club_events.dart' show EventsCampsView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, userAllowedForEvents;
import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

/// Camps list screen at `/memberzone/events/camps`.
class EventsCampsScreen extends ConsumerWidget {
  const EventsCampsScreen({
    required this.onEventTap,
    required this.onHome,
    this.onEnrollments,
    this.onCreateNew,
    this.onBack,
    super.key,
  });

  final void Function(Event event) onEventTap;
  final void Function(Event event)? onEnrollments;
  final VoidCallback? onCreateNew;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (!userAllowedForEvents(user)) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to view this page.',
        onHome: onHome,
      );
    }
    return EventsCampsView(
      currentUser: user!,
      onEventTap: onEventTap,
      onEnrollments: onEnrollments,
      onCreateNew: onCreateNew,
      onBack: onBack,
    );
  }
}
