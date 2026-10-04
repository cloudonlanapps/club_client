import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyEventDetailProvider, clMyOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_event_counts.dart';
import '../models/my_range_occurrences_key.dart';

/// Member-facing day-event counts.
///
/// Mirrors `dayEventCountsProvider` but reads from the member endpoints
/// (`/myevents/{username}/occurrences` + `/myevents/{username}/events/{id}`)
/// so it can be used from `MyEventsCalendarView` without hitting the
/// admin-only `/occurrences/` route.
final AutoDisposeFutureProviderFamily<
  Map<DateTime, DayEventCounts>,
  MyRangeOccurrencesKey
>
myDayEventCountsProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DayEventCounts>, MyRangeOccurrencesKey>((
      ref,
      key,
    ) async {
      final occurrences = await ref.watch(
        clMyOccurrencesProvider((
          username: key.username,
          from: key.range.start,
          to: key.range.end,
        )).future,
      );

      final uniqueEventIds = <int>{for (final occ in occurrences) occ.eventId};

      final eventTypeMap = <int, EventType>{};
      for (final eventId in uniqueEventIds) {
        final event = await ref.watch(
          clMyEventDetailProvider((
            username: key.username,
            eventId: eventId,
          )).future,
        );
        eventTypeMap[eventId] = event.type;
      }

      final result = <DateTime, DayEventCounts>{};
      for (final occ in occurrences) {
        final date = DateUtils.dateOnly(occ.actualStartTimeUtc);
        final eventType = eventTypeMap[occ.eventId];
        if (eventType == null) continue;

        final current = result[date] ?? (programme: 0, oneoff: 0, camp: 0);
        result[date] = switch (eventType) {
          EventType.programme => (
            programme: current.programme + 1,
            oneoff: current.oneoff,
            camp: current.camp,
          ),
          EventType.oneOff => (
            programme: current.programme,
            oneoff: current.oneoff + 1,
            camp: current.camp,
          ),
          EventType.camp => (
            programme: current.programme,
            oneoff: current.oneoff,
            camp: current.camp + 1,
          ),
        };
      }

      return result;
    });
