// The server takes no UNTIL on a programme's rule: its end is written only
// by terminate, extend and split (club_client#121).
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventFormType, ProgrammeScheduleData;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../support/recording_create_events.dart';

void main() {
  test('Issue 121: a programme is created with a weekly rule and no '
      'UNTIL', () async {
    final sent = await createWith(
      EventFormType.programme,
      ProgrammeScheduleData(
        weekdays: const {DateTime.monday},
        startDate: DateTime(2026, 10, 19),
        sessionStartTime: const ShadTimeOfDay(hour: 12, minute: 0, second: 0),
      ),
    );

    expect(sent.rrule, 'FREQ=WEEKLY;BYDAY=MO');
  });
}
