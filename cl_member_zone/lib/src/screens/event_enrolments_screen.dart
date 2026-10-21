import 'package:cl_club_events/cl_club_events.dart' show EventEnrolmentsView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show RoleGate, userAllowedForEvents;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enrolments management screen at `/memberzone/events/:eventId/enrollments`.
class EventEnrolmentsScreen extends ConsumerWidget {
  const EventEnrolmentsScreen({
    required this.eventId,
    required this.onHome,
    this.onBack,
    this.onOpenReview,
    super.key,
  });

  final int eventId;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  /// Opens an evaluation a coach started from a row (club_core#174).
  final ValueChanged<int>? onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: userAllowedForEvents,
      onHome: onHome,
      builder: (user) {
        return EventEnrolmentsView(
          currentUser: user,
          eventId: eventId,
          onBack: onBack,
          onOpenReview: onOpenReview,
        );
      },
    );
  }
}
