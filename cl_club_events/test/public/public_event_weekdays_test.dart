// A rule names its weekdays in UTC; a page shows them in the viewer's time
// zone, as it shows the session times (club_client#120).
import 'package:cl_club_events/cl_club_events.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/day_apart.dart';
import 'support/public_events.dart';

void main() {
  test(
    'Issue 120: a programme held on local Monday and Wednesday reads '
    '"Mon, Wed" when its UTC days differ',
    () {
      final time = dayApartTime;
      final monday = DateTime(2026, 10, 19, time.hour, time.minute);
      final wednesday = DateTime(2026, 10, 21, time.hour, time.minute);

      final view = testEventView(
        testPublicEvent(
          type: EventType.programme,
          rrule: 'FREQ=WEEKLY;BYDAY=${utcByDay(monday)},${utcByDay(wednesday)}',
          start: monday,
          length: const Duration(hours: 1),
        ),
      );

      expect(view.effectiveSchedule, 'Mon, Wed');
    },
    skip: skipUnlessDayApart,
  );

  test(
    'Issue 120: the landing page tells programmes apart by their local '
    'weekday, not by the UTC day their rules name',
    () {
      final time = dayApartTime;
      // Local Monday, on the neighbouring UTC day.
      final monday = DateTime(2026, 10, 19, time.hour, time.minute);
      // Noon on that neighbouring day: the same UTC weekday, another local
      // one.
      final mondayUtc = monday.toUtc();
      final noon = DateTime(mondayUtc.year, mondayUtc.month, mondayUtc.day, 12);
      final sameUtcDay = 'FREQ=WEEKLY;BYDAY=${utcByDay(monday)}';

      PublicEventView programme(String id, DateTime start) => testEventView(
        testPublicEvent(
          publicId: id,
          type: EventType.programme,
          rrule: sameUtcDay,
          start: start,
        ),
      );

      final picked = selectLandingEvents(EventType.programme, [
        programme('early', monday),
        programme('noon', noon),
        programme('early-again', monday.add(const Duration(days: 7))),
      ]);

      expect(picked.map((e) => e.publicId), ['early', 'noon']);
    },
    skip: skipUnlessDayApart,
  );

  test("Issue 120: at noon the derived schedule names the rule's days", () {
    final view = testEventView(
      testPublicEvent(
        type: EventType.programme,
        rrule: 'FREQ=WEEKLY;BYDAY=WE,MO',
        start: DateTime(2026, 10, 19, 12),
      ),
    );

    expect(view.effectiveSchedule, 'Mon, Wed');
  });
}
