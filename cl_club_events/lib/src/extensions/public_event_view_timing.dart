import 'package:club_sdk_2/club_sdk_2.dart' show EventSession;

import '../models/public/event_time_slot.dart';
import '../models/public/public_event_view.dart';
import '../utils/public_event_format.dart';

/// When a public event happens, with fallbacks for the marketing block's
/// free text.
///
/// The server sends `durationText` and `scheduleText` only when an admin has
/// written them, and not at all when the marketing module is off. Everything
/// here derives the same fact from the event's own window and rrule, so a page
/// reads the same whether or not anyone filled the field in.
extension PublicEventViewTiming on PublicEventView {
  /// The marketing schedule text if set, else derived from the rrule
  /// ("Mon, Tue", "Daily"), its weekdays in the viewer's timezone; null if
  /// neither is available.
  String? get effectiveSchedule {
    final text = schedule;
    if (text != null && text.isNotEmpty) return text;
    return deriveScheduleFromRrule(rrule, startTimeUtc);
  }

  /// The marketing duration text if set, else derived from the event's own
  /// window in the viewer's timezone.
  String? get effectiveDuration {
    final text = duration;
    if (text != null && text.isNotEmpty) return text;
    return deriveDurationFromTimes(
      startTimeUtc.toLocal(),
      endTimeUtc.toLocal(),
      type,
    );
  }

  /// The occurrence's timetable, as clock ranges in the viewer's timezone.
  ///
  /// The server sends no timing text at all any more: an occurrence is a
  /// start–end window plus an ordered `sessions` list of `{name,
  /// periodMinutes}` whose periods sum to that window. Walking the list from
  /// the window's start turns it back into wall-clock ranges.
  ///
  /// A window with no sessions, or with a single one, is one undivided slot
  /// and gets no label — the label would only repeat what the page already
  /// says. Anything longer is a real timetable and each row keeps its name.
  List<EventTimeSlot> get timetable {
    final start = startTimeUtc.toLocal();
    final slots = sessions ?? const <EventSession>[];
    if (slots.length < 2) {
      return [EventTimeSlot(start: start, end: endTimeUtc.toLocal())];
    }

    final rows = <EventTimeSlot>[];
    var cursor = start;
    for (final session in slots) {
      final end = cursor.add(Duration(minutes: session.periodMinutes));
      rows.add(EventTimeSlot(start: cursor, end: end, label: session.name));
      cursor = end;
    }
    return rows;
  }

  /// The timetable as display strings, one per row.
  List<String> get effectiveTimings =>
      timetable.map((slot) => slot.display).toList();
}
