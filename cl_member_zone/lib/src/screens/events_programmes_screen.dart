import 'package:cl_club_events/cl_club_events.dart' show EventsProgrammesView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show RoleGate, userAllowedForEvents;
import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Programmes list screen at `/memberzone/events/programmes`.
class EventsProgrammesScreen extends ConsumerWidget {
  const EventsProgrammesScreen({
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
    return RoleGate(
      allow: userAllowedForEvents,
      onHome: onHome,
      builder: (user) {
        return EventsProgrammesView(
          currentUser: user,
          onEventTap: onEventTap,
          onEnrollments: onEnrollments,
          onCreateNew: onCreateNew,
          onBack: onBack,
        );
      },
    );
  }
}
