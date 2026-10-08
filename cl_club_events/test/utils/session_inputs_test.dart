// The SDK ↔ form translation of a session split that runs past midnight
// (issue 64): the form's times wrap to the next day, and each session is
// sent with its real length.
import 'package:cl_club_events/src/models/event_create_form_helpers.dart';
import 'package:cl_club_events/src/utils/session_inputs.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        CampScheduleData,
        EventCreateFormFields,
        EventFormType,
        EventFormVisibility,
        ProgrammeScheduleData,
        SessionInput;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

const ShadTimeOfDay _elevenPm = ShadTimeOfDay(hour: 23, minute: 0, second: 0);

const _hours = [
  EventSession(name: 'Warm-up', periodMinutes: 60),
  EventSession(name: 'Match', periodMinutes: 60),
];

/// Two hours from eleven at night, an hour each, as the form writes them.
const _acrossMidnight = [
  SessionInput(name: 'Warm-up', startTime: '23:00', endTime: '00:00'),
  SessionInput(name: 'Match', startTime: '00:00', endTime: '01:00'),
];

/// Records the sessions of the one `createEvent` call it expects.
class _RecordingNotifier extends ClEventsMasterNotifier {
  List<EventSession>? sessions;

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
    this.sessions = sessions;
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
      sessions: sessions,
    );
  }
}

Future<List<EventSession>?> _createdSessions(
  EventFormType type,
  Object schedule,
) async {
  final notifier = _RecordingNotifier();
  await EventCreateFormSubmit.create(
    type: type,
    values: {
      EventCreateFormFields.titleId: 'Late session',
      EventCreateFormFields.visibilityId: EventFormVisibility.public,
      EventCreateFormFields.venueId: 7,
      EventCreateFormFields.scheduleId: schedule,
    },
    notifier: notifier,
  );
  return notifier.sessions;
}

void main() {
  group('Issue 64: sessions across midnight, SDK to form', () {
    test('Issue 64: the split of an occurrence that runs past midnight is '
        'seeded with wrapped times', () {
      expect(
        sessionInputsFromEventSessions(_hours, _elevenPm),
        _acrossMidnight,
      );
    });
  });

  group('Issue 64: sessions across midnight, form to SDK', () {
    test('Issue 64: a session that ends after midnight is sent with its '
        'length', () {
      expect(eventSessionsFromSessionInputs(_acrossMidnight), _hours);
    });

    test('Issue 64: what is seeded from the SDK is sent back unchanged', () {
      expect(
        eventSessionsFromSessionInputs(
          sessionInputsFromEventSessions(_hours, _elevenPm),
        ),
        _hours,
      );
    });

    test('Issue 64: a camp created with a split across midnight sends each '
        'session with its length', () async {
      expect(
        await _createdSessions(
          EventFormType.camp,
          CampScheduleData(
            startDate: DateTime(2030, 7),
            trainingDays: 3,
            sessionStartTime: _elevenPm,
            sessions: _acrossMidnight,
          ),
        ),
        _hours,
      );
    });

    test('Issue 64: a programme created with a split across midnight sends '
        'each session with its length', () async {
      expect(
        await _createdSessions(
          EventFormType.programme,
          ProgrammeScheduleData(
            weekdays: const {DateTime.monday},
            startDate: DateTime(2030, 5, 6),
            sessionStartTime: _elevenPm,
            totalDurationMinutes: 120,
            sessions: _acrossMidnight,
          ),
        ),
        _hours,
      );
    });
  });
}
