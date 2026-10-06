import 'package:cl_club_events/src/models/camp_event_form_helpers.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        AgeEligibilityFormFields,
        AgeEligibilityFormValues,
        EventFormFields,
        EventGender,
        FormAge;

Event _event({
  EventType type = EventType.camp,
  Gender? gender,
  Age? minAge,
  Age? maxAge,
  bool strictAge = false,
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
    type: type,
    visibility: Visibility.public,
    venueId: 7,
    startTimeUtc: DateTime.utc(2026, 5, 1, 9),
    endTimeUtc: DateTime.utc(2026, 5, 1, 11),
    createdAtUtc: DateTime.utc(2026),
    updatedAtUtc: DateTime.utc(2026),
    gender: gender,
    minAge: minAge,
    maxAge: maxAge,
    strictAge: strictAge,
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

    test('Issue 678: maps gender, age band, and organizer from event', () {
      final values = buildEventFormInitialValues(
        _event(
          gender: Gender.female,
          minAge: const Age(years: 5),
          maxAge: const Age(years: 18, months: 6),
          strictAge: true,
          // The server's computed dates are read-only: the form takes ages.
          dobOnOrAfterUtc: DateTime.utc(2010),
          dobOnOrBeforeUtc: DateTime.utc(2014),
          organizerName: 'EXC',
          coachNames: const ['Asha', 'Ravi'],
        ),
      );

      expect(values[EventFormFields.genderId], EventGender.female);
      expect(AgeEligibilityFormValues.minAge(values), const FormAge(years: 5));
      expect(
        AgeEligibilityFormValues.maxAge(values),
        const FormAge(years: 18, months: 6),
      );
      expect(AgeEligibilityFormValues.strictAge(values), isTrue);
      expect(values.values.whereType<DateTime>(), isEmpty);
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

  group('Issue 33: EventFormSubmit.updateEligibility', () {
    Map<String, dynamic> form({
      EventGender? gender,
      String minYears = '',
      String maxYears = '',
      bool strict = false,
    }) => {
      EventFormFields.genderId: gender,
      ...AgeEligibilityFormValues.initial(strictAge: strict),
      AgeEligibilityFormFields.minAgeYearsId: minYears,
      AgeEligibilityFormFields.maxAgeYearsId: maxYears,
    };

    test(
      'Issue 33: 5 and 18 years send minAge, maxAge and strictAge',
      () async {
        final notifier = _RecordingNotifier(_event());
        await EventFormSubmit.updateEligibility(
          event: _event(),
          values: form(minYears: '5', maxYears: '18', strict: true),
          notifier: notifier,
        );

        final sent = notifier.updates.single;
        expect(sent.minAge!(), const Age(years: 5));
        expect(sent.maxAge!(), const Age(years: 18));
        expect(sent.strictAge, isTrue);
        expect(sent.gender!(), isNull);
        expect(notifier.corrections, isEmpty);
      },
    );

    test('Issue 33: an emptied age clears that bound', () async {
      final notifier = _RecordingNotifier(_event());
      await EventFormSubmit.updateEligibility(
        event: _event(
          minAge: const Age(years: 5),
          maxAge: const Age(years: 18),
        ),
        values: form(minYears: '5', gender: EventGender.female),
        notifier: notifier,
      );

      final sent = notifier.updates.single;
      expect(sent.minAge!(), const Age(years: 5));
      expect(sent.maxAge, isNotNull, reason: 'a getter, so the bound clears');
      expect(sent.maxAge!(), isNull);
      expect(sent.strictAge, isFalse);
      expect(sent.gender!(), Gender.female);
    });

    test('Issue 33: months and days travel with the years', () async {
      final notifier = _RecordingNotifier(_event());
      await EventFormSubmit.updateEligibility(
        event: _event(),
        values: {
          ...form(minYears: '5'),
          AgeEligibilityFormFields.minAgeMonthsId: '6',
          AgeEligibilityFormFields.minAgeDaysId: '2',
        },
        notifier: notifier,
      );

      expect(
        notifier.updates.single.minAge!(),
        const Age(years: 5, months: 6, days: 2),
      );
    });

    test("Issue 33: a programme's eligibility goes through "
        'correctionOnEvent', () async {
      final programme = _event(type: EventType.programme);
      final notifier = _RecordingNotifier(programme);
      await EventFormSubmit.updateEligibility(
        event: programme,
        values: form(minYears: '5', maxYears: '18'),
        notifier: notifier,
      );

      expect(notifier.updates, isEmpty);
      final sent = notifier.corrections.single;
      expect(sent.minAge!(), const Age(years: 5));
      expect(sent.maxAge!(), const Age(years: 18));
      expect(sent.strictAge, isFalse);
    });

    test(
      "Issue 33: a one-off's eligibility goes through updateEvent",
      () async {
        final oneOff = _event(type: EventType.oneOff);
        final notifier = _RecordingNotifier(oneOff);
        await EventFormSubmit.updateEligibility(
          event: oneOff,
          values: form(maxYears: '12'),
          notifier: notifier,
        );

        expect(notifier.corrections, isEmpty);
        expect(notifier.updates.single.minAge!(), isNull);
        expect(notifier.updates.single.maxAge!(), const Age(years: 12));
      },
    );
  });
}

/// What one eligibility write carried.
class _Sent {
  _Sent(this.gender, this.minAge, this.maxAge, {required this.strictAge});
  final Gender? Function()? gender;
  final Age? Function()? minAge;
  final Age? Function()? maxAge;
  final bool? strictAge;
}

/// Records the eligibility writes the adapter sends, by verb.
class _RecordingNotifier extends ClEventsMasterNotifier {
  _RecordingNotifier(this.returnEvent);

  final Event returnEvent;
  final List<_Sent> updates = [];
  final List<_Sent> corrections = [];

  @override
  Future<Event> updateEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) async {
    updates.add(_Sent(gender, minAge, maxAge, strictAge: strictAge));
    return returnEvent;
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    corrections.add(_Sent(gender, minAge, maxAge, strictAge: strictAge));
    return returnEvent;
  }
}
