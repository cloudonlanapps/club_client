// Run with TZ=Asia/Kolkata to see the failure these guard against: the
// session below is 05:00 local on 5 Nov, which is 2026-11-04T23:30Z there.
// In UTC the instant and the local day agree and every test passes trivially.
import 'package:cl_calendar/cl_calendar.dart';
import 'package:cl_club_events/src/models/my_range_occurrences_key.dart';
import 'package:cl_club_events/src/providers/cached_occurrences.dart';
import 'package:cl_club_events/src/providers/date_items_notifier.dart';
import 'package:cl_club_events/src/providers/day_event_counts.dart';
import 'package:cl_club_events/src/providers/my_day_event_counts.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/staff_calendar_fixtures.dart';

void main() {
  final range = MonthViewRange(year: 2026, month: 11);
  final camp = calendarEvent(1, EventType.camp);
  final startUtc = DateTime(2026, 11, 5, 5).toUtc();
  final localDay = DateTime(2026, 11, 5);
  final dayBefore = DateTime(2026, 11, 4);

  group('Issue 209: the staff calendar places a session on its local day', () {
    test(
      'Issue 209: the day dot counts the session under its local day',
      () async {
        final container = staffCalendarContainer(
          events: [camp],
          occurrences: [calendarOccurrence(camp.id, startUtc)],
        );
        final key = (range: range);
        container.listen(cachedOccurrencesProvider(key), (_, _) {});
        await settle(
          () => !container.read(cachedOccurrencesProvider(key)).isLoading,
        );

        final counts = await container.read(dayEventCountsProvider(key).future);

        expect(counts[localDay]?.camp, 1);
        expect(counts[dayBefore], isNull);
      },
    );

    test('Issue 209: the session lists under its local day only', () async {
      final container = staffCalendarContainer(
        events: [camp],
        occurrences: [calendarOccurrence(camp.id, startUtc)],
      );

      final onDay = await container.read(
        dateItemsNotifierProvider((date: localDay, range: range)).future,
      );
      final before = await container.read(
        dateItemsNotifierProvider((date: dayBefore, range: range)).future,
      );

      expect(onDay.map((i) => i.$1.actualStartTimeUtc), [startUtc]);
      expect(before, isEmpty);
    });
  });

  test(
    'Issue 209: the member calendar counts the session under its local day',
    () async {
      const username = 'member209';
      final container = ProviderContainer(
        overrides: [
          clMyOccurrencesProvider.overrideWith(
            (ref, key) async => [calendarOccurrence(camp.id, startUtc)],
          ),
          clMyEventDetailProvider.overrideWith((ref, key) async => camp),
        ],
      );
      addTearDown(container.dispose);
      final MyRangeOccurrencesKey key = (username: username, range: range);

      final counts = await container.read(
        myDayEventCountsProvider(key).future,
      );

      expect(counts[localDay]?.camp, 1);
      expect(counts[dayBefore], isNull);
    },
  );
}
