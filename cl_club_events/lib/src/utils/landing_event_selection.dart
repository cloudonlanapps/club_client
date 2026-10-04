import 'package:club_sdk_2/club_sdk_2.dart' show EventType;

import '../models/public/public_event_view.dart';
import 'public_event_format.dart';

/// How many events a landing page section shows.
const int kMaxLandingEvents = 2;

/// The events a landing page section shows, from the active ones of [type].
///
/// Camps and one-offs: the soonest to start. Programmes: ones that run on
/// different days of the week, for variety, falling back to the first ones
/// when there are not enough distinct days.
List<PublicEventView> selectLandingEvents(
  EventType type,
  List<PublicEventView> events,
) {
  if (type != EventType.programme) {
    final sorted = [...events]
      ..sort((a, b) => a.startTimeUtc.compareTo(b.startTimeUtc));
    return sorted.take(kMaxLandingEvents).toList();
  }

  if (events.length <= kMaxLandingEvents) return events;
  final selected = <PublicEventView>[];
  final usedDays = <String>{};
  for (final program in events) {
    final day = firstRruleDay(program.rrule);
    if (day != null && usedDays.add(day)) {
      selected.add(program);
      if (selected.length >= kMaxLandingEvents) break;
    }
  }
  if (selected.length < kMaxLandingEvents) {
    return events.take(kMaxLandingEvents).toList();
  }
  return selected;
}
