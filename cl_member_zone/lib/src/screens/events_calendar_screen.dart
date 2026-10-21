import 'package:cl_club_events/cl_club_events.dart' show EventsCalendarView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show RoleGate, userAllowedForEvents;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return RoleGate(
      allow: userAllowedForEvents,
      onHome: onHome,
      builder: (user) {
        return EventsCalendarView(
          currentUser: user,
          onMarkAttendance: onMarkAttendance,
          onBack: onBack,
        );
      },
    );
  }
}
