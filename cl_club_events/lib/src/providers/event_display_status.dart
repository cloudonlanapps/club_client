import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventDetailProvider, clEventSchedulesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_display_status.dart';

/// Computes the [EventDisplayStatus] for an event.
///
/// Watches [clEventDetailProvider] and [clEventSchedulesProvider] so it
/// auto-updates when splits, terminations or cancellations occur.
///
/// Status logic (club_core#16):
/// - **Ended / Cancelled**: the cutoff (`untilTimeUtc`) has been reached —
///   ended for a programme, cancelled for a camp / one-off. A cutoff still
///   ahead does not change the status: the event keeps running until then.
/// - **Coming Soon**: no schedule has started yet.
/// - **Ended**: camp / one-off whose last occurrence (via rrule) is past.
/// - **Ongoing**: everything else that's active.
final FutureProviderFamily<EventDisplayStatus, int> eventDisplayStatusProvider =
    FutureProvider.family<EventDisplayStatus, int>((ref, eventId) async {
      final event = await ref.watch(clEventDetailProvider(eventId).future);
      final schedules = await ref.watch(
        clEventSchedulesProvider(eventId).future,
      );

      return computeDisplayStatus(event, schedules);
    });

EventDisplayStatus computeDisplayStatus(
  Event event,
  List<EventSchedule> schedules, {
  DateTime? now,
}) {
  final nowUtc = (now ?? DateTime.now()).toUtc();

  // Cutoff reached: a terminated programme has ended; a cancelled camp or a
  // dropped one-off is cancelled. Before the cutoff the event still runs.
  if (isEventSeriesCancelled(event, now: nowUtc)) {
    return event.type == EventType.programme
        ? EventDisplayStatus.ended
        : EventDisplayStatus.cancelled;
  }

  // Coming Soon: no schedule has started yet.
  if (isTimetableComingSoon(event, schedules, nowUtc)) {
    return EventDisplayStatus.comingSoon;
  }

  // Ended: camp/oneoff whose last occurrence is past
  if (event.type != EventType.programme) {
    final lastEnd = computeLastOccurrenceEnd(event);
    if (lastEnd != null && lastEnd.isBefore(nowUtc)) {
      return EventDisplayStatus.ended;
    }
  }

  return EventDisplayStatus.ongoing;
}

/// Whether nothing in the timetable has started yet: the earliest schedule
/// start (or the event's own start when no schedules are known) is still
/// ahead of [now].
bool isTimetableComingSoon(
  Event event,
  List<EventSchedule> schedules,
  DateTime now,
) {
  var earliest = event.startTimeUtc;
  for (final schedule in schedules) {
    if (schedule.startTimeUtc.isBefore(earliest)) {
      earliest = schedule.startTimeUtc;
    }
  }
  return earliest.isAfter(now);
}

/// Computes the actual last occurrence end time for camps/oneoff.
///
/// Delegates to the SDK helper [lastOccurrenceEndUtc], which is now
/// the single source of truth for series-end calculation across the
/// app (also used by [isPastEvent] — see #686). Kept here as a
/// nullable-returning wrapper so existing call sites continue to
/// compile; the SDK helper returns non-null because every Event has
/// at least a single-occurrence end.
DateTime? computeLastOccurrenceEnd(Event event) => lastOccurrenceEndUtc(event);
