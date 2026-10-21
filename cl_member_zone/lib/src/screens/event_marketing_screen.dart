import 'package:cl_club_events/cl_club_events.dart' show EventMarketingView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show RoleGate, userAllowedForEvents;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An event's Marketing page at `/memberzone/events/:eventId/marketing`
/// (club_client#1). Staff reach the route; the view itself turns away
/// anyone who is neither an admin nor the event's organizer.
class EventMarketingScreen extends ConsumerWidget {
  const EventMarketingScreen({
    required this.eventId,
    required this.onHome,
    this.onBack,
    super.key,
  });

  /// The event.
  final int eventId;

  /// Goes home.
  final VoidCallback onHome;

  /// Leaves the page.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: userAllowedForEvents,
      onHome: onHome,
      builder: (user) {
        return EventMarketingView(
          currentUser: user,
          eventId: eventId,
          onBack: onBack,
          onHome: onHome,
        );
      },
    );
  }
}
