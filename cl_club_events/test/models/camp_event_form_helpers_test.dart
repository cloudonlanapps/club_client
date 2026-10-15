import 'package:cl_club_events/src/models/camp_event_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        AgeEligibilityFormValues,
        EligibilityGender,
        EventFormFields,
        FormAge,
        GenderEligibilityFormValues;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event({
  EventType type = EventType.camp,
  List<Gender> genders = const [],
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
    genders: genders,
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
      expect(GenderEligibilityFormValues.genders(values), isEmpty);
    });

    test('Issue 678: maps gender, age band, and organizer from event', () {
      final values = buildEventFormInitialValues(
        _event(
          genders: const [Gender.female],
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

      expect(GenderEligibilityFormValues.genders(values), [
        EligibilityGender.girls,
      ]);
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

        // No gender criterion is no ticked gender.
        expect(GenderEligibilityFormValues.genders(values), isEmpty);
        expect(values[EventFormFields.organizerNameId], '');
        expect(values[EventFormFields.coachNamesId], const <String>[]);
      },
    );
  });

  group('Issue 33: EventFormSubmit.updateEligibility', () {
    Map<String, dynamic> form({
      List<EligibilityGender> genders = const [],
      String minYears = '',
      String maxYears = '',
      bool strict = false,
    }) => {
      ...GenderEligibilityFormValues.initial(genders),
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
        // No gender ticked, as the event has none: not sent.
        expect(sent.genders, isNull);
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
        values: form(
          minYears: '5',
          genders: const [EligibilityGender.girls],
        ),
        notifier: notifier,
      );

      final sent = notifier.updates.single;
      expect(sent.minAge!(), const Age(years: 5));
      expect(sent.maxAge, isNotNull, reason: 'a getter, so the bound clears');
      expect(sent.maxAge!(), isNull);
      expect(sent.strictAge, isFalse);
      expect(sent.genders!(), [Gender.female]);
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

  group('Issue 80: the event adapter sends the ticked genders', () {
    Map<String, dynamic> form(
      List<EligibilityGender> genders, {
      String maxYears = '',
    }) => {
      ...GenderEligibilityFormValues.initial(genders),
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

    const three = [
      EligibilityGender.boys,
      EligibilityGender.other,
      EligibilityGender.preferNotToSay,
    ];

    test('Issue 80: stored genders show as their ticked boxes', () {
      final values = buildEventFormInitialValues(
        _event(
          genders: const [Gender.preferNotToSay, Gender.male, Gender.other],
        ),
      );

      expect(GenderEligibilityFormValues.genders(values), three);
    });

    test('Issue 80: Boys, Other and Prefer not to say on a camp send exactly '
        'those three through updateEvent', () async {
      final notifier = _RecordingNotifier(_event());
      await EventFormSubmit.updateEligibility(
        event: _event(),
        values: form(three),
        notifier: notifier,
      );

      expect(notifier.corrections, isEmpty);
      expect(notifier.updates.single.genders!(), [
        Gender.male,
        Gender.other,
        Gender.preferNotToSay,
      ]);
    });

    test('Issue 80: Boys, Other and Prefer not to say on a programme send '
        'exactly those three through correctionOnEvent', () async {
      final programme = _event(type: EventType.programme);
      final notifier = _RecordingNotifier(programme);
      await EventFormSubmit.updateEligibility(
        event: programme,
        values: form(three),
        notifier: notifier,
      );

      expect(notifier.updates, isEmpty);
      expect(notifier.corrections.single.genders!(), [
        Gender.male,
        Gender.other,
        Gender.preferNotToSay,
      ]);
    });

    test('Issue 80: unticking every box sends an empty list, which clears '
        'the criterion', () async {
      for (final type in [EventType.camp, EventType.programme]) {
        final sent = await save(
          _event(type: type, genders: const [Gender.male, Gender.female]),
          form(const []),
        );

        expect(sent.genders, isNotNull, reason: '$type: a getter');
        expect(sent.genders!(), isEmpty, reason: '$type');
      }
    });

    test('Issue 80: genders equal to the stored ones, in any order, are not '
        'sent', () async {
      for (final type in [EventType.camp, EventType.programme]) {
        final event = _event(
          type: type,
          genders: const [Gender.preferNotToSay, Gender.male, Gender.other],
        );
        final sent = await save(event, form(three, maxYears: '12'));

        expect(sent.genders, isNull, reason: '$type');
        expect(sent.maxAge!(), const Age(years: 12));
      }
    });

    test('Issue 80: a section saved without touching the boxes does not '
        'send genders', () async {
      final event = _event(genders: const [Gender.female, Gender.other]);
      final sent = await save(event, {
        ...buildEventFormInitialValues(event),
        AgeEligibilityFormFields.maxAgeYearsId: '12',
      });

      expect(sent.genders, isNull);
      expect(sent.maxAge!(), const Age(years: 12));
    });
  });
}

/// What one eligibility write carried.
class _Sent {
  _Sent(this.genders, this.minAge, this.maxAge, {required this.strictAge});
  final List<Gender> Function()? genders;
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
    List<Gender> Function()? genders,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) async {
    updates.add(_Sent(genders, minAge, maxAge, strictAge: strictAge));
    return returnEvent;
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    List<Gender> Function()? genders,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    corrections.add(_Sent(genders, minAge, maxAge, strictAge: strictAge));
    return returnEvent;
  }
}
