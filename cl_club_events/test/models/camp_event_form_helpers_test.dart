import 'package:cl_club_events/src/models/camp_event_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show AgeEligibilityFormValues, EventFormFields, EventGender, FormAge;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(values[EventFormFields.genderId], EventGender.any);
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

      expect(values[EventFormFields.genderId], EventGender.girls);
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

        // Since #78 no gender criterion is the entry Any, never null.
        expect(values[EventFormFields.genderId], EventGender.any);
        expect(values[EventFormFields.organizerNameId], '');
        expect(values[EventFormFields.coachNamesId], const <String>[]);
      },
    );
  });

  group('Issue 33: EventFormSubmit.updateEligibility', () {
    Map<String, dynamic> form({
      EventGender gender = EventGender.any,
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
        // Gender stayed on Any, as the event has it: not sent (#78).
        expect(sent.gender, isNull);
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
        values: form(minYears: '5', gender: EventGender.girls),
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

  group('Issue 78: the event adapter maps Any, Boys and Girls', () {
    Map<String, dynamic> form(EventGender gender, {String maxYears = ''}) => {
      EventFormFields.genderId: gender,
      ...AgeEligibilityFormValues.initial(),
      AgeEligibilityFormFields.maxAgeYearsId: maxYears,
    };

    Future<_Sent> save(Event event, Map<String, dynamic> values) async {
      final notifier = _RecordingNotifier(event);
      await EventFormSubmit.updateEligibility(
        event: event,
        values: values,
        notifier: notifier,
      );
      return [...notifier.updates, ...notifier.corrections].single;
    }

    test('Issue 78: a stored gender shows as Boys, Girls or Any', () {
      expect(
        {
          for (final g in <Gender?>[null, ...Gender.values])
            g: EventFormSubmit.genderToForm(g),
        },
        {
          null: EventGender.any,
          Gender.male: EventGender.boys,
          Gender.female: EventGender.girls,
          Gender.other: EventGender.any,
          Gender.preferNotToSay: EventGender.any,
        },
      );
      for (final g in <Gender?>[null, ...Gender.values]) {
        expect(
          buildEventFormInitialValues(
            _event(gender: g),
          )[EventFormFields.genderId],
          EventFormSubmit.genderToForm(g),
          reason: '$g',
        );
      }
    });

    test('Issue 78: Any stores no gender, Boys male and Girls female', () {
      expect(
        {for (final g in EventGender.values) g: EventFormSubmit.genderToSdk(g)},
        {
          EventGender.any: null,
          EventGender.boys: Gender.male,
          EventGender.girls: Gender.female,
        },
      );
    });

    test('Issue 78: Boys or Girls picked on an open event is sent', () async {
      expect(
        (await save(_event(), form(EventGender.boys))).gender!(),
        Gender.male,
      );
      expect(
        (await save(_event(), form(EventGender.girls))).gender!(),
        Gender.female,
      );
    });

    test('Issue 78: Any picked on a boys or girls event sends no gender '
        'criterion', () async {
      for (final stored in [Gender.male, Gender.female]) {
        final sent = await save(_event(gender: stored), form(EventGender.any));

        expect(sent.gender, isNotNull, reason: 'a getter, so it clears');
        expect(sent.gender!(), isNull);
      }
    });

    test('Issue 78: a stored other criterion is not sent when Gender is '
        'untouched', () async {
      for (final stored in [Gender.other, Gender.preferNotToSay]) {
        final event = _event(gender: stored);
        final values = {
          ...buildEventFormInitialValues(event),
          AgeEligibilityFormFields.maxAgeYearsId: '12',
        };
        expect(values[EventFormFields.genderId], EventGender.any);

        final sent = await save(event, values);

        expect(sent.gender, isNull, reason: '$stored stays as stored');
        expect(sent.maxAge!(), const Age(years: 12));
      }
    });

    test('Issue 78: a stored other criterion is replaced when an entry is '
        'picked', () async {
      final event = _event(gender: Gender.other);

      expect(
        (await save(event, form(EventGender.girls))).gender!(),
        Gender.female,
      );
      expect(
        (await save(event, form(EventGender.boys))).gender!(),
        Gender.male,
      );
    });

    test('Issue 78: an unchanged Boys or Girls is not sent either, on a '
        'camp or a programme', () async {
      for (final type in [EventType.camp, EventType.programme]) {
        final event = _event(type: type, gender: Gender.male);
        final sent = await save(
          event,
          form(EventGender.boys, maxYears: '12'),
        );

        expect(sent.gender, isNull, reason: '$type');
        expect(sent.maxAge!(), const Age(years: 12));
      }
    });

    test("Issue 78: a programme's changed gender goes with the "
        'correction', () async {
      final programme = _event(type: EventType.programme, gender: Gender.male);
      final notifier = _RecordingNotifier(programme);
      await EventFormSubmit.updateEligibility(
        event: programme,
        values: form(EventGender.any),
        notifier: notifier,
      );

      expect(notifier.updates, isEmpty);
      expect(notifier.corrections.single.gender!(), isNull);
    });
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
