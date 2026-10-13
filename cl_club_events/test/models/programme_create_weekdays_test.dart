// Everything sent to the server is in UTC, a rule's weekdays included: the
// server expands a weekly rule from the UTC start (club_client#119).
import 'package:cl_club_events/src/utils/programme_schedule_sessions.dart'
    show programmeRuleWeekdays;
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormType, ProgrammeScheduleData;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../support/day_apart.dart';
import '../support/recording_create_events.dart';

void main() {
  test(
    'Issue 119: a programme created at a time whose UTC day differs names '
    'its UTC weekdays in the rule',
    () async {
      final time = dayApartTime;
      // Monday 19 and Wednesday 21 October 2026, local.
      final monday = DateTime(2026, 10, 19, time.hour, time.minute);
      final wednesday = DateTime(2026, 10, 21, time.hour, time.minute);

      final sent = await createWith(
        EventFormType.programme,
        ProgrammeScheduleData(
          weekdays: const {DateTime.monday, DateTime.wednesday},
          startDate: DateTime(2026, 10, 19),
          sessionStartTime: time,
        ),
      );

      expect(sent.startTimeUtc, monday.toUtc());
      expect(
        programmeRuleWeekdays(sent.rrule),
        {monday.toUtc().weekday, wednesday.toUtc().weekday},
        reason:
            'the server reads BYDAY from the UTC start '
            '(${utcByDay(monday)}), so local Monday and Wednesday are '
            '${utcByDay(monday)} and ${utcByDay(wednesday)}',
      );
    },
    skip: skipUnlessDayApart,
  );

  test('Issue 119: at noon the rule names the weekdays as picked', () async {
    final sent = await createWith(
      EventFormType.programme,
      ProgrammeScheduleData(
        weekdays: const {DateTime.monday, DateTime.wednesday},
        startDate: DateTime(2026, 10, 19),
        sessionStartTime: const ShadTimeOfDay(hour: 12, minute: 0, second: 0),
      ),
    );

    final noon = DateTime(2026, 10, 19, 12);
    expect(programmeRuleWeekdays(sent.rrule), {
      noon.toUtc().weekday,
      noon.add(const Duration(days: 2)).toUtc().weekday,
    });
  });
}
