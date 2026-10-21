import 'package:cl_club_events/src/models/camp_schedule_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show CampScheduleData, EventFormType, SessionInput;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../support/recording_create_events.dart';

void main() {
  group('Issue 215: create and reschedule assemble a camp the same way', () {
    test('Issue 215: a camp with a rest day and a split sends the schedule '
        'the reschedule assembles', () async {
      final data = CampScheduleData(
        startDate: DateTime(2026, 11, 2),
        trainingDays: 4,
        sessionStartTime: const ShadTimeOfDay(hour: 7, minute: 30, second: 0),
        durationMinutes: 150,
        excludedDates: {DateTime(2026, 11, 4)},
        sessions: const [
          SessionInput(name: 'On-Ice', startTime: '07:30', endTime: '09:00'),
          SessionInput(name: 'Off-Ice', startTime: '09:00', endTime: '10:00'),
        ],
      );

      final sent = await createWith(EventFormType.camp, data);
      final assembled = assembleCampSchedule(data);

      expect(sent.startTimeUtc, assembled.startUtc);
      expect(sent.endTimeUtc, assembled.endUtc);
      expect(sent.rrule, assembled.rrule);
      expect(sent.sessions, assembled.sessions);
    });

    test('Issue 215: a camp with no split sends no sessions', () async {
      final data = CampScheduleData(
        startDate: DateTime(2026, 11, 2),
        trainingDays: 3,
        sessionStartTime: const ShadTimeOfDay(hour: 18, minute: 0, second: 0),
      );

      final sent = await createWith(EventFormType.camp, data);
      final assembled = assembleCampSchedule(data);

      expect(sent.rrule, assembled.rrule);
      expect(sent.sessions, isNull);
    });
  });
}
