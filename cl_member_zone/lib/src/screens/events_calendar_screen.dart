import 'package:cl_club_events/cl_club_events.dart' show EventsCalendarView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, userAllowedForEvents;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

/// Admin/coach calendar screen at `/memberzone/events/calendar`.
class EventsCalendarScreen extends ConsumerWidget {
  const EventsCalendarScreen({
    required this.onMarkAttendance,
    required this.onHome,
    this.onBack,
    super.key,
  });

  final void Function(int eventId, DateTime occurrenceTimeUtc) onMarkAttendance;
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
    return EventsCalendarView(
      currentUser: user!,
      onMarkAttendance: onMarkAttendance,
      onBack: onBack,
    );
  }
}
