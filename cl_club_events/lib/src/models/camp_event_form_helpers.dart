import 'package:cl_club_forms/cl_club_forms.dart'
    show AgeEligibilityFormValues, EventFormFields, EventGender;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, formAgeFromSdk, sdkAgeFromForm;
import 'package:club_sdk_2/club_sdk_2.dart'
    show Age, Event, EventType, Gender, Visibility;

/// SDK ↔ form adapter for the camp-event section editors — the one place that
/// bridges the forms' flat `Map<String, dynamic>` (keyed by [EventFormFields],
/// with the form-local [EventGender]) to the `cl_remote_store` update calls.
///
/// The form widgets (`EventEligibilityForm`, `EventOrganizerForm`,
/// `EventMediaForm`) are SDK-free in `ui_lib`; this helper owns the
/// translation. Mirrors `user_form_helpers.dart` / `group_form_helpers.dart` /
/// `venue_form_helpers.dart`.

/// Builds initial form values from an existing [Event] (null = create
/// defaults). Text fields normalize `null` → `''` and list fields → `const []`
/// so each form's `isDirty` comparison works cleanly. Gender is never null:
/// an event with no gender criterion holds [EventGender.any].
Map<String, dynamic> buildEventFormInitialValues(Event? event) {
  if (event == null) {
    return {
      EventFormFields.titleId: '',
      EventFormFields.descriptionId: '',
      EventFormFields.genderId: EventGender.any,
      ...AgeEligibilityFormValues.initial(),
      EventFormFields.organizerNameId: '',
      EventFormFields.coachNamesId: const <String>[],
    };
  }
  return {
    EventFormFields.titleId: event.title,
    EventFormFields.descriptionId: event.description,
    EventFormFields.genderId: EventFormSubmit.genderToForm(event.gender),
    ...AgeEligibilityFormValues.initial(
      minAge: formAgeFromSdk(event.minAge),
      maxAge: formAgeFromSdk(event.maxAge),
      strictAge: event.strictAge,
    ),
    EventFormFields.organizerNameId: event.organizerName ?? '',
    EventFormFields.coachNamesId:
        event.coachNames ??
        event.coaches?.map((c) => c.displayName).toList() ??
        const <String>[],
  };
}

/// Bridges the section forms' values to the SDK update calls. Each section
/// method sends **only** its own fields (rule 21): nullable axes use a
/// `ValueGetter` so they can be cleared, while fields the section doesn't edit
/// are left out entirely (the notifier treats an absent value as "no change").
class EventFormSubmit {
  const EventFormSubmit._();

  /// The Gender entry an event's stored [gender] shows as: Boys for male,
  /// Girls for female, Any for none. A criterion the field does not offer
  /// (`other`, `preferNotToSay`, set through the API) shows as Any too.
  static EventGender genderToForm(Gender? gender) => switch (gender) {
    Gender.male => EventGender.boys,
    Gender.female => EventGender.girls,
    Gender.other || Gender.preferNotToSay || null => EventGender.any,
  };

  /// What the picked [gender] stores: male for Boys, female for Girls, and
  /// `null` (no gender criterion) for Any.
  static Gender? genderToSdk(EventGender gender) => switch (gender) {
    EventGender.boys => Gender.male,
    EventGender.girls => Gender.female,
    EventGender.any => null,
  };

  /// Rename (management section) — `title` is a direct field on the server.
  static Future<Event> updateTitle({
    required int eventId,
    required String title,
    required ClEventsMasterNotifier notifier,
  }) {
    return notifier.updateEvent(eventId, title: title.trim());
  }

  /// Description (markdown section) — direct field; an empty string clears it.
  static Future<Event> updateDescription({
    required int eventId,
    required String description,
    required ClEventsMasterNotifier notifier,
  }) {
    return notifier.updateEvent(eventId, description: description.trim());
  }

  /// Eligibility section — gender and the age band (`minAge`, `maxAge`,
  /// `strictAge`); no dates are sent, the server works the window out. An
  /// emptied age clears that bound.
  ///
  /// The gender is sent only when the form's differs from the entry
  /// [event]'s stored gender shows as ([genderToForm]): a stored criterion
  /// the field does not offer, which shows as Any, is then kept by a save
  /// that leaves Gender alone. A changed gender is sent, Any as `null`.
  ///
  /// A programme's eligibility is a correction (`correctionOnEvent`); a
  /// camp's or one-off's goes through `updateEvent`. The server refuses the
  /// other verb for each type.
  static Future<Event> updateEligibility({
    required Event event,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    final picked = EventGender.of(values);
    final gender = picked == genderToForm(event.gender)
        ? null
        : () => genderToSdk(picked);
    Age? minAge() => sdkAgeFromForm(AgeEligibilityFormValues.minAge(values));
    Age? maxAge() => sdkAgeFromForm(AgeEligibilityFormValues.maxAge(values));
    final strictAge = AgeEligibilityFormValues.strictAge(values);
    if (event.type == EventType.programme) {
      return notifier.correctionOnEvent(
        event.id,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
        strictAge: strictAge,
      );
    }
    return notifier.updateEvent(
      event.id,
      gender: gender,
      minAge: minAge,
      maxAge: maxAge,
      strictAge: strictAge,
    );
  }

  /// Organizer & coaches section. `organizerName` is a direct field (sending
  /// the trimmed value, possibly empty); `coachNames` is a clearable list.
  static Future<Event> updateOrganizer({
    required int eventId,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    final coaches =
        (values[EventFormFields.coachNamesId] as List<String>?) ?? const [];
    return notifier.updateEvent(
      eventId,
      organizerName:
          (values[EventFormFields.organizerNameId] as String?)?.trim() ?? '',
      coachNames: () => coaches,
    );
  }

  /// Flags section — visibility + featured, both direct fields persisted
  /// immediately on toggle.
  static Future<Event> updateFlags({
    required int eventId,
    required ClEventsMasterNotifier notifier,
    Visibility? visibility,
    bool? isFeatured,
  }) {
    return notifier.updateEvent(
      eventId,
      visibility: visibility,
      isFeatured: isFeatured,
    );
  }
}
