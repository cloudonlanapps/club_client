import 'package:cl_remote_store/src/models/aggregated_my_event.dart';
import 'package:cl_remote_store/src/providers/my_enrollment.dart';
import 'package:cl_remote_store/src/providers/my_events_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aggregates enrolled events across multiple users, deduplicating by event ID.
///
/// Keyed by a set of usernames. For each username, watches
/// [clMyEventsMasterProvider] for their events, then collects enrollment
/// data per event. Events appearing for multiple users are merged into
/// a single [AggregatedMyEvent] with multiple enrollments.
final AutoDisposeFutureProviderFamily<List<AggregatedMyEvent>, Set<String>>
clMyEventsAggregatedProvider = FutureProvider.autoDispose
    .family<List<AggregatedMyEvent>, Set<String>>(
      (ref, usernames) async {
        if (usernames.isEmpty) return [];

        // Collect events per user.
        final allEvents = <int, Event>{};
        final eventEnrollments = <int, List<Enrollment>>{};

        for (final username in usernames) {
          final events = await ref.watch(
            clMyEventsMasterProvider(username).future,
          );

          for (final event in events) {
            allEvents.putIfAbsent(event.id, () => event);

            final enrollment = await ref.watch(
              clMyEnrollmentProvider(
                (username: username, eventId: event.id),
              ).future,
            );

            if (enrollment != null) {
              eventEnrollments.putIfAbsent(event.id, () => []).add(enrollment);
            }
          }
        }

        // Build aggregated list sorted by start time ascending.
        final aggregated =
            allEvents.entries.map((entry) {
              return AggregatedMyEvent(
                event: entry.value,
                enrollments: eventEnrollments[entry.key] ?? [],
              );
            }).toList()..sort(
              (a, b) => a.event.startTimeUtc.compareTo(b.event.startTimeUtc),
            );

        return aggregated;
      },
    );
