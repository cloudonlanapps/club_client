import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/day_event_counts.dart';
import '../models/range_occurrences_key.dart';
import 'cached_occurrences.dart';
import 'event_notifier.dart';

/// Provider for pre-computed occurrence counts per day, grouped by event type.
/// Returns `Map<DateTime, DayEventCounts>` (DateTime is date only).
/// Takes (user, range) key as parameter.
///
/// Counts OCCURRENCES by type, not unique events.
/// E.g., if Event 123 (Programme) has 3 sessions on March 1st, count = 3.
///
/// Optimized to fetch each unique event only once, even if it has multiple
/// occurrences.
final AutoDisposeFutureProviderFamily<
  Map<DateTime, DayEventCounts>,
  RangeOccurrencesKey
>
dayEventCountsProvider = FutureProvider.autoDispose
    .family<Map<DateTime, DayEventCounts>, RangeOccurrencesKey>((
      ref,
      key,
    ) async {
      final cached = ref.watch(cachedOccurrencesProvider(key));

      // Use cached data if available, otherwise use empty list during loading
      final occurrences = cached.data ?? [];

      // Step 1: Collect unique event IDs
      final uniqueEventIds = <int>{};
      for (final occ in occurrences) {
        uniqueEventIds.add(occ.eventId);
      }

      // Step 2: Fetch each unique event once (creates reactive dependency)
      final eventTypeMap = <int, EventType>{};
      for (final eventId in uniqueEventIds) {
        final event = await ref.watch(eventNotifierProvider(eventId).future);
        eventTypeMap[eventId] = event.type;
      }

      // Step 3: Count occurrences per day, grouped by event type
      final result = <DateTime, DayEventCounts>{};

      for (final occ in occurrences) {
        // Normalize to date only (UTC midnight)
        final date = DateUtils.dateOnly(occ.actualStartTimeUtc);

        // Get event type from pre-fetched map
        final eventType = eventTypeMap[occ.eventId];
        if (eventType == null) continue;

        // Get current counts or default
        final current = result[date] ?? (programme: 0, oneoff: 0, camp: 0);

        // Increment the appropriate count
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
