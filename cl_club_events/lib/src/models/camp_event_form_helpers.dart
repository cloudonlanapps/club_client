import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, Gender, Visibility;
import 'package:ui_lib/ui_lib.dart' show EventFormFields, EventGender;

/// SDK ↔ form adapter for the camp-event section editors — the one place that
/// bridges the forms' flat `Map<String, dynamic>` (keyed by [EventFormFields],
/// with the form-local [EventGender]) to the `cl_remote_store` update calls.
///
/// The form widgets (`EventEligibilityForm`, `EventOrganizerForm`,
/// `EventMediaForm`) are SDK-free in `ui_lib`; this helper owns the
/// translation. Mirrors `user_form_helpers.dart` / `group_form_helpers.dart` /
/// `venue_form_helpers.dart`.

/// Form-local [EventGender] → SDK [Gender].
Gender? _genderToSdk(EventGender? g) => switch (g) {
  EventGender.male => Gender.male,
  EventGender.female => Gender.female,
  EventGender.other => Gender.other,
  EventGender.preferNotToSay => Gender.preferNotToSay,
  null => null,
};

/// SDK [Gender] → form-local [EventGender].
EventGender? _genderToForm(Gender? g) => switch (g) {
  Gender.male => EventGender.male,
  Gender.female => EventGender.female,
  Gender.other => EventGender.other,
  Gender.preferNotToSay => EventGender.preferNotToSay,
  null => null,
};

DateTime? _floorToUtcMidnight(DateTime? d) {
  if (d == null) return null;
  return DateTime.utc(d.year, d.month, d.day);
}

/// Builds initial form values from an existing [Event] (null = create
/// defaults). Text fields normalize `null` → `''` and list fields → `const []`
/// so each form's `isDirty` comparison works cleanly.
Map<String, dynamic> buildEventFormInitialValues(Event? event) {
  if (event == null) {
    return {
      EventFormFields.titleId: '',
      EventFormFields.descriptionId: '',
      EventFormFields.organizerNameId: '',
      EventFormFields.coachNamesId: const <String>[],
    };
  }
  return {
    EventFormFields.titleId: event.title,
    EventFormFields.descriptionId: event.description,
    EventFormFields.genderId: _genderToForm(event.gender),
    EventFormFields.dobOnOrAfterId: event.dobOnOrAfterUtc,
    EventFormFields.dobOnOrBeforeId: event.dobOnOrBeforeUtc,
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

  /// Eligibility section — gender + DOB window, all clearable via ValueGetter.
  static Future<Event> updateEligibility({
    required int eventId,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    return notifier.updateEvent(
      eventId,
      gender: () =>
          _genderToSdk(values[EventFormFields.genderId] as EventGender?),
      dobOnOrAfterUtc: () => _floorToUtcMidnight(
        values[EventFormFields.dobOnOrAfterId] as DateTime?,
      ),
      dobOnOrBeforeUtc: () => _floorToUtcMidnight(
        values[EventFormFields.dobOnOrBeforeId] as DateTime?,
      ),
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
