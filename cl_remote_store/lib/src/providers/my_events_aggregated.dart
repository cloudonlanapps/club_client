import 'package:cl_remote_store/src/models/aggregated_my_event.dart';
import 'package:cl_remote_store/src/providers/my_enrollment.dart';
import 'package:cl_remote_store/src/providers/my_events_master.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A member's events, each with the member's enrollment, sorted by start
/// time ascending.
///
/// Keyed by username. Watches [clMyEventsMasterProvider] for the member's
/// events, then reads every event's enrollment at once
/// (club_client#237).
final AutoDisposeFutureProviderFamily<List<AggregatedMyEvent>, String>
clMyEventsAggregatedProvider = FutureProvider.autoDispose
    .family<List<AggregatedMyEvent>, String>(
      (ref, username) async {
        final events = await ref.watch(
          clMyEventsMasterProvider(username).future,
        );
        final enrollments = await Future.wait([
          for (final event in events)
            ref.watch(
              clMyEnrollmentProvider(
                (username: username, eventId: event.id),
              ).future,
            ),
        ]);
        return [
          for (var i = 0; i < events.length; i++)
            AggregatedMyEvent(event: events[i], enrollment: enrollments[i]),
        ]..sort(
          (a, b) => a.event.startTimeUtc.compareTo(b.event.startTimeUtc),
        );
      },
    );
