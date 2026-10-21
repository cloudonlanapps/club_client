import 'package:cl_club_events/cl_club_events.dart'
    show EventsProgrammesNewView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show RoleGate, userAllowedForEvents;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// New-programme screen at `/memberzone/events/programmes/new`.
class EventsProgrammesNewScreen extends ConsumerWidget {
  const EventsProgrammesNewScreen({
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
    return RoleGate(
      allow: userAllowedForEvents,
      onHome: onHome,
      deniedMessage: 'You do not have permission to create events.',
      builder: (user) {
        // Only coaches/admins may create events; members are denied the route.
        return EventsProgrammesNewView(
          currentUser: user,
          onCreated: onCreated,
          onCancel: onCancel,
        );
      },
    );
  }
}
