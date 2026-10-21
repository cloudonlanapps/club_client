import 'package:cl_club_events/cl_club_events.dart'
    show EventOccurencesAttendanceView, RemovedEventView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show RoleGate, userAllowedForEvents;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventDetailProvider, clEventsMasterProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView, LoadingView;

import '../utils/master_errors.dart';

/// Per-occurrence attendance screen.
class EventOccurencesAttendanceScreen extends ConsumerWidget {
  const EventOccurencesAttendanceScreen({
    required this.eventId,
    required this.occurrenceTimeUtc,
    required this.onHome,
    required this.onDismissed,
    this.sourceNotificationId,
    this.onBack,
    super.key,
  });

  final int eventId;
  final DateTime occurrenceTimeUtc;
  final int? sourceNotificationId;
  final VoidCallback onHome;

  /// Leaves this page when the event no longer exists. Wired from the router.
  final VoidCallback onDismissed;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGate(
      allow: userAllowedForEvents,
      onHome: onHome,
      builder: (user) {
        final eventAsync = ref.watch(clEventDetailProvider(eventId));

        return eventAsync.when(
          skipLoadingOnReload: true,
          loading: () => const LoadingView(),
          error: (error, _) {
            if (isMasterNotFoundError(error)) {
              return RemovedEventView(
                eventId: eventId,
                sourceNotificationId: sourceNotificationId,
                onDismissed: onDismissed,
              );
            }
            return ErrorView(
              title: 'Could not load event',
              errorCode: '$error',
              onHome: onHome,
              onRetry: () => ref.invalidate(clEventsMasterProvider),
            );
          },
          data: (_) => EventOccurencesAttendanceView(
            currentUser: user,
            eventId: eventId,
            occurrenceTimeUtc: occurrenceTimeUtc,
            onBack: onBack,
          ),
        );
      },
    );
  }
}
