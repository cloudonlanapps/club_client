import 'package:cl_club_forms/cl_club_forms.dart';

import '../constants/demo_sizes.dart';
import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'demo_samples.dart';
import 'fake_host_calls.dart';

/// The forms that create an event and edit its sections.
abstract final class EventEntries {
  /// The entries, in the order shown.
  static List<FormDemoEntry> get all => [
    for (final type in [
      EventFormType.camp,
      EventFormType.programme,
      EventFormType.oneOff,
    ])
      create(type),
    FormDemoEntry(
      id: 'event-eligibility',
      title: 'Event eligibility form',
      group: FormDemoGroup.events,
      formType: EventEligibilityForm,
      builder: (key) => EventEligibilityForm(
        key: key,
        initialValues: {
          EventFormFields.genderId: EventGender.girls,
          ...AgeEligibilityFormValues.initial(
            minAge: const FormAge(years: 8),
            maxAge: const FormAge(years: 12, months: 6),
          ),
        },
      ),
    ),
    FormDemoEntry(
      id: 'event-staff',
      title: 'Event staff form',
      group: FormDemoGroup.events,
      formType: EventStaffForm,
      builder: (key) => EventStaffForm(
        key: key,
        initialValues: {
          EventFormFields.organizerNameId: DemoSamples.organizer,
          EventFormFields.coachNamesId: DemoSamples.coaches,
        },
        onPickOrganizer: FakeHostCalls.pickOrganizer,
        onPickCoaches: FakeHostCalls.pickCoaches,
      ),
    ),
    FormDemoEntry(
      id: 'event-cancellation-sessions',
      title: 'Event cancellation form, camp with sessions',
      group: FormDemoGroup.events,
      formType: EventCancellationForm,
      builder: (key) => EventCancellationForm(
        key: key,
        sessions: [
          for (var day = 1; day <= DemoSamples.campTrainingDays; day++)
            EventCancellationSession(
              start: DemoSamples.inDays(
                day,
              ).add(const Duration(hours: DemoSamples.startHour)),
              label: 'Day $day, ${DemoSamples.startHour}:00',
            ),
        ],
      ),
    ),
    FormDemoEntry(
      id: 'event-cancellation',
      title: 'Event cancellation form, no sessions',
      group: FormDemoGroup.events,
      formType: EventCancellationForm,
      builder: (key) => EventCancellationForm(key: key),
    ),
  ];

  /// The create form of an event of [type], as it opens: empty, with the
  /// schedule the form proposes.
  static FormDemoEntry create(EventFormType type) => FormDemoEntry(
    id: 'event-create-${type.name}',
    title: 'Event create form, ${type.label.toLowerCase()}',
    group: FormDemoGroup.events,
    formType: EventCreateForm,
    maxWidth: DemoSizes.wideFormMaxWidth,
    builder: (key) => EventCreateForm(
      key: key,
      eventType: type,
      venues: DemoSamples.venues,
      initialValues: EventCreateForm.defaultValues(
        type,
        now: DemoSamples.today.add(
          const Duration(hours: DemoSamples.startHour - 1),
        ),
      ),
    ),
  );
}
