// A programme's description is corrected; a camp's is updated
// (club_client#118).
import 'package:cl_club_events/src/models/camp_event_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/programme_fixtures.dart';
import '../support/recording_edit_events.dart';

void main() {
  final programme = programmeFixture();
  final camp = programme.copyWith(
    type: EventType.camp,
    rrule: () => 'FREQ=DAILY;COUNT=3',
  );

  test(
    "Issue 118: a programme's description is saved as a correction",
    () async {
      final events = RecordingEditEvents(programme);

      await EventFormSubmit.updateDescription(
        event: programme,
        description: ' Skating for all. ',
        notifier: events,
      );

      expectOneEdit(events, correctionVerb, {
        'description': 'Skating for all.',
      });
    },
  );

  test("Issue 118: a camp's description is saved as an update", () async {
    final events = RecordingEditEvents(camp);

    await EventFormSubmit.updateDescription(
      event: camp,
      description: 'Skating for all.',
      notifier: events,
    );

    expectOneEdit(events, updateVerb, {'description': 'Skating for all.'});
  });

  test("Issue 118: a programme's unchanged organizer and coaches send "
      'nothing', () async {
    final staffed = programme.copyWith(
      organizerName: () => 'org',
      coachNames: () => const ['coach_a'],
    );
    final events = RecordingEditEvents(staffed);

    await EventFormSubmit.updateOrganizer(
      event: staffed,
      values: {
        'organizerName': 'org',
        'coachNames': const ['coach_a'],
        'effectiveFrom': DateTime.utc(2030),
      },
      notifier: events,
    );

    expect(events.sent, isEmpty);
  });
}
