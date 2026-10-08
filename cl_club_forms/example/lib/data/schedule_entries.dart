import 'package:cl_club_forms/cl_club_forms.dart';

import '../constants/demo_sizes.dart';
import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';
import 'fake_host_calls.dart';

/// The forms that say when an event runs.
abstract final class ScheduleEntries {
  /// The session of the sample one-off and of the sample occurrence.
  static OneOffScheduleData get oneOff => OneOffScheduleData(
    date: DemoSamples.inDays(DemoSamples.soonDays),
    startTime: DemoSamples.startTime,
    durationMinutes: DemoSamples.durationMinutes,
  );

  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    FormDemoEntry(
      id: 'camp-schedule',
      title: 'Camp schedule form',
      group: FormDemoGroup.schedules,
      formType: CampScheduleForm,
      maxWidth: DemoSizes.wideFormMaxWidth,
      builder: (key) => CampScheduleForm(
        key: key,
        initialValue: CampScheduleData(
          startDate: DemoSamples.inDays(DemoSamples.soonDays),
          trainingDays: DemoSamples.campTrainingDays,
          sessionStartTime: DemoSamples.startTime,
          durationMinutes: DemoSamples.durationMinutes,
          excludedDates: {DemoSamples.inDays(DemoSamples.soonDays + 2)},
          sessions: DemoSamples.sessions,
        ),
      ),
    ),
    FormDemoEntry(
      id: 'one-off-schedule',
      title: 'One-off schedule form',
      group: FormDemoGroup.schedules,
      formType: OneOffScheduleForm,
      maxWidth: DemoSizes.wideFormMaxWidth,
      builder: (key) => OneOffScheduleForm(
        key: key,
        venues: DemoSamples.venues,
        notBefore: DemoSamples.today,
        initialValue: OneOffScheduleValue(
          schedule: oneOff,
          venueId: DemoSamples.venueId,
          sessions: DemoSamples.sessions,
        ),
      ),
    ),
    FormDemoEntry(
      id: 'event-timetable',
      title: 'Event timetable form',
      group: FormDemoGroup.schedules,
      formType: EventTimetableForm,
      maxWidth: DemoSizes.wideFormMaxWidth,
      builder: (key) => EventTimetableForm(
        key: key,
        initialScheduleIndex: 1,
        note:
            'Corrects the timetable of every session of this schedule; '
            'no dates move.',
        schedules: const [
          TimetableScheduleOption(
            id: 21,
            label: 'Until last month, 18:00, 1h',
            startTime: DemoSamples.startTime,
            totalMinutes: 60,
          ),
          TimetableScheduleOption(
            id: 22,
            label: 'Current, 18:00, 2h',
            startTime: DemoSamples.startTime,
            totalMinutes: DemoSamples.durationMinutes,
            sessions: DemoSamples.sessions,
          ),
        ],
      ),
    ),
    FormDemoEntry(
      id: 'programme-schedule-adjust',
      title: 'Programme schedule adjust form',
      group: FormDemoGroup.schedules,
      formType: ProgrammeScheduleAdjustForm,
      maxWidth: DemoSizes.wideFormMaxWidth,
      builder: (key) {
        final fromOptions = [
          for (var week = 1; week <= 3; week++)
            DemoSamples.inDays(
              week * DateTime.daysPerWeek,
            ).add(const Duration(hours: DemoSamples.startHour)),
        ];
        return ProgrammeScheduleAdjustForm(
          key: key,
          fromOptions: fromOptions,
          venues: DemoSamples.venues,
          initialValue: ProgrammeScheduleAdjustValue(
            from: fromOptions.first,
            venueId: DemoSamples.venueId,
            schedule: ProgrammeScheduleData(
              weekdays: const {DateTime.monday, DateTime.thursday},
              startDate: DemoSamples.today,
              sessionStartTime: DemoSamples.startTime,
              totalDurationMinutes: DemoSamples.durationMinutes,
              sessions: DemoSamples.sessions,
            ),
          ),
        );
      },
    ),
    FormDemoEntry(
      id: 'programme-end-date',
      title: 'Programme end date form',
      group: FormDemoGroup.schedules,
      formType: ProgrammeEndDateForm,
      builder: (key) => ProgrammeEndDateForm(
        key: key,
        initialValues: {
          ProgrammeEndDateFormFields.lastDayId: DemoSamples.inDays(
            DemoSamples.laterDays,
          ),
        },
        reasonRequired: true,
        resultOf: FakeHostCalls.endDateResult,
      ),
    ),
    FormDemoEntry(
      id: 'occurrence-reschedule',
      title: 'Occurrence reschedule form',
      group: FormDemoGroup.schedules,
      formType: OccurrenceRescheduleForm,
      maxWidth: DemoSizes.wideFormMaxWidth,
      builder: (key) => OccurrenceRescheduleForm(
        key: key,
        venues: DemoSamples.venues,
        initialValues: {
          OccurrenceRescheduleFormFields.scheduleId: oneOff,
          OccurrenceRescheduleFormFields.venueId: DemoSamples.venueId,
        },
      ),
    ),
  ];
}
