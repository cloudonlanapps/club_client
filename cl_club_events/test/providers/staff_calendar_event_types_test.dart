import 'package:cl_calendar/cl_calendar.dart';
import 'package:cl_club_events/src/providers/cached_occurrences.dart';
import 'package:cl_club_events/src/providers/date_items_notifier.dart';
import 'package:cl_club_events/src/providers/day_event_counts.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/staff_calendar_fixtures.dart';

void main() {
  group('Issue 219: the staff calendar shows the club event types only', () {
    final range = MonthViewRange(year: 2026, month: 11);
    final camp = calendarEvent(1, EventType.camp);
    final programme = calendarEvent(2, EventType.programme);
    final campDay = DateTime(2026, 11, 10);
    final programmeDay = DateTime(2026, 11, 12);
    final occurrences = [
      calendarOccurrence(camp.id, DateTime.utc(2026, 11, 10, 10)),
      calendarOccurrence(programme.id, DateTime.utc(2026, 11, 12, 10)),
    ];

    test(
      'Issue 219: a programme session leaves no count in a camps-only club',
      () async {
        final container = staffCalendarContainer(
          events: [camp, programme],
          occurrences: occurrences,
        );
        final key = (range: range);
        container.listen(cachedOccurrencesProvider(key), (_, _) {});
        await settle(
          () => !container.read(cachedOccurrencesProvider(key)).isLoading,
        );

        final counts = await container.read(
          dayEventCountsProvider(key).future,
        );

        expect(counts[campDay]?.camp, 1);
        expect(counts[programmeDay], isNull);
      },
    );

    test(
      'Issue 219: a programme session lists on no day in a camps-only club',
      () async {
        final container = staffCalendarContainer(
          events: [camp, programme],
          occurrences: occurrences,
        );

        final campItems = await container.read(
          dateItemsNotifierProvider((date: campDay, range: range)).future,
        );
        final programmeItems = await container.read(
          dateItemsNotifierProvider((date: programmeDay, range: range)).future,
        );

        expect(campItems.map((i) => i.$2.id), [camp.id]);
        expect(programmeItems, isEmpty);
      },
    );
  });
}
