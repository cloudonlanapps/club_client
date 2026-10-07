import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import '../../models/camp_schedule_data.dart';
import '../../models/one_off_schedule_data.dart';
import '../../models/programme_schedule_data.dart';
import 'event_create_form_fields.dart';

/// What a fresh `EventCreateForm` opens with.
class EventCreateFormDefaults {
  const EventCreateFormDefaults._();

  /// How far ahead of now a programme or a one-off starts.
  static const Duration leadTime = Duration(hours: 1);

  /// How far ahead of now a camp starts.
  static const Duration campLeadTime = Duration(days: 1);

  /// Training days of a new camp.
  static const int campTrainingDays = 5;

  /// Daily start of a new camp.
  static const ShadTimeOfDay campStartTime = ShadTimeOfDay(
    hour: 6,
    minute: 0,
    second: 0,
  );

  /// Daily length of a new camp, in minutes.
  static const int campDurationMinutes = 90;

  /// The values of a fresh event of [type]: empty title, public, no venue
  /// selected, and a default schedule seeded from [now].
  static Map<String, dynamic> values(EventFormType type, {DateTime? now}) => {
    EventCreateFormFields.titleId: '',
    EventCreateFormFields.visibilityId: EventFormVisibility.public,
    EventCreateFormFields.venueId: null,
    EventCreateFormFields.scheduleId: schedule(type, now ?? DateTime.now()),
  };

  /// The default schedule object of [type], seeded from [now].
  static Object schedule(EventFormType type, DateTime now) {
    switch (type) {
      case EventFormType.programme:
        // The next whole hour, dated by that hour, so a form opened late in
        // the evening does not start the series at midnight already past.
        final next = now.add(leadTime);
        return ProgrammeScheduleData(
          startDate: DateTime(next.year, next.month, next.day),
          sessionStartTime: ShadTimeOfDay(
            hour: next.hour,
            minute: 0,
            second: 0,
          ),
        );
      case EventFormType.camp:
        return CampScheduleData(
          startDate: now.add(campLeadTime),
          trainingDays: campTrainingDays,
          sessionStartTime: campStartTime,
          durationMinutes: campDurationMinutes,
        );
      case EventFormType.oneOff:
        final start = now.add(leadTime);
        return OneOffScheduleData(
          date: DateTime(start.year, start.month, start.day),
          startTime: ShadTimeOfDay(
            hour: start.hour,
            minute: start.minute,
            second: 0,
          ),
        );
    }
  }
}
