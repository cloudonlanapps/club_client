import 'package:cl_club_events/src/models/camp_event_form_helpers.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show EventFormFields, EventGender;

Event _event({
  Gender? gender,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
  String? organizerName,
  List<String>? coachNames,
  List<PublicProfile>? coaches,
}) {
  return Event(
    id: 1,
    title: 'Summer Camp',
    description: 'A camp',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 7,
    startTimeUtc: DateTime.utc(2026, 5, 1, 9),
    endTimeUtc: DateTime.utc(2026, 5, 1, 11),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
    gender: gender,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
    organizerName: organizerName,
    coachNames: coachNames,
    coaches: coaches,
  );
}

void main() {
  group('buildEventFormInitialValues', () {
    test('Issue 678: null event → create defaults (empty strings + lists)', () {
      final values = buildEventFormInitialValues(null);
      expect(values[EventFormFields.titleId], '');
      expect(values[EventFormFields.descriptionId], '');
      expect(values[EventFormFields.organizerNameId], '');
      expect(values[EventFormFields.coachNamesId], const <String>[]);
    });

    test('Issue 678: maps gender, DOB window, and organizer from event', () {
      final values = buildEventFormInitialValues(
        _event(
          gender: Gender.female,
          dobOnOrAfterUtc: DateTime.utc(2010),
          dobOnOrBeforeUtc: DateTime.utc(2014),
          organizerName: 'EXC',
          coachNames: const ['Asha', 'Ravi'],
        ),
      );

      expect(values[EventFormFields.genderId], EventGender.female);
      expect(values[EventFormFields.dobOnOrAfterId], DateTime.utc(2010));
      expect(values[EventFormFields.dobOnOrBeforeId], DateTime.utc(2014));
      expect(values[EventFormFields.organizerNameId], 'EXC');
      expect(values[EventFormFields.coachNamesId], const ['Asha', 'Ravi']);
    });

    test('Issue 678: coachNames falls back to coach display names', () {
      final values = buildEventFormInitialValues(
        _event(
          coaches: const [
            PublicProfile(publicId: 'a', displayName: 'Coach A'),
            PublicProfile(publicId: 'b', displayName: 'Coach B'),
          ],
        ),
      );

      expect(values[EventFormFields.coachNamesId], const [
        'Coach A',
        'Coach B',
      ]);
    });

    test(
      'Issue 678: null optionals normalize to empty string / empty list',
      () {
        final values = buildEventFormInitialValues(_event());

        expect(values[EventFormFields.genderId], isNull);
        expect(values[EventFormFields.organizerNameId], '');
        expect(values[EventFormFields.coachNamesId], const <String>[]);
      },
    );
  });
}
