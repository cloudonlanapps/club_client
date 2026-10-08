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
}
