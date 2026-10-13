import 'package:cl_club_events/src/models/event_create_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventCreateFormFields, EventFormType, EventFormVisibility;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';

/// Records the schedule of the one `createEvent` call it expects.
class RecordingCreateEvents extends ClEventsMasterNotifier {
  DateTime? startTimeUtc;
  String? rrule;

  @override
  Future<Event> createEvent({
    required String title,
    required String description,
    required EventType type,
    required Visibility visibility,
    required int venueId,
    required DateTime startTimeUtc,
    required DateTime endTimeUtc,
    String? organizerName,
    List<String>? coachNames,
    String? rrule,
    Gender? gender,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    bool isFeatured = false,
    List<String>? galleryUris,
    List<EventSession>? sessions,
  }) async {
    this.startTimeUtc = startTimeUtc;
    this.rrule = rrule;
    return Event(
      id: 1,
      title: title,
      description: description,
      type: type,
      visibility: visibility,
      venueId: venueId,
      startTimeUtc: startTimeUtc,
      endTimeUtc: endTimeUtc,
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    );
  }
}

/// What the create adapter sends for [schedule] of [type].
Future<RecordingCreateEvents> createWith(
  EventFormType type,
  Object schedule,
) async {
  final notifier = RecordingCreateEvents();
  await EventCreateFormSubmit.create(
    type: type,
    values: {
      EventCreateFormFields.titleId: 'Early skate',
      EventCreateFormFields.visibilityId: EventFormVisibility.public,
      EventCreateFormFields.venueId: 7,
      EventCreateFormFields.scheduleId: schedule,
    },
    notifier: notifier,
  );
  return notifier;
}
