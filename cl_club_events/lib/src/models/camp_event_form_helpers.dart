import 'package:cl_club_forms/cl_club_forms.dart'
    show AgeEligibilityFormValues, EventFormFields, EventGender;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, formAgeFromSdk, sdkAgeFromForm;
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        Age,
        Event,
        EventType,
        Gender,
        SdkErrorCode,
        ServerException,
        StaleVersionException,
        Visibility;

import 'package:flutter/foundation.dart' show listEquals;

import '../utils/event_refusal.dart';
import '../utils/schedule_save_error.dart';

/// SDK ↔ form adapter for the event section editors — the one place that
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
///
/// The server offers `updateEvent` to camps and one-offs only. A programme's
/// identity, eligibility and presentation are a **correction**
/// (`correctionOnEvent`), and its staffing changes by a **split** from a
/// session onward (`updateEventForAllFuture`); each method picks the verb
/// from the event's type (club_client#118).
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

  /// Rename (management section): a correction of a programme's title, an
  /// update of a camp's or a one-off's.
  static Future<Event> updateTitle({
    required Event event,
    required String title,
    required ClEventsMasterNotifier notifier,
  }) {
    final trimmed = title.trim();
    if (event.type == EventType.programme) {
      return notifier.correctionOnEvent(event.id, title: trimmed);
    }
    return notifier.updateEvent(event.id, title: trimmed);
  }

  /// Description (markdown section): a correction of a programme's, an
  /// update of a camp's or a one-off's. An empty string clears it.
  static Future<Event> updateDescription({
    required Event event,
    required String description,
    required ClEventsMasterNotifier notifier,
  }) {
    final trimmed = description.trim();
    if (event.type == EventType.programme) {
      return notifier.correctionOnEvent(event.id, description: trimmed);
    }
    return notifier.updateEvent(event.id, description: trimmed);
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

  /// Shown inline when the server refuses a minimum age above the maximum.
  static const String invertedBandMessage =
      'Minimum age must not be greater than maximum age.';

  /// Shown on the organizer when the server no longer knows them.
  static const String organizerGoneMessage =
      'The organizer no longer has an account. Pick another.';

  /// Shown on the coaches when the server no longer knows one of them.
  static const String coachGoneMessage =
      'A coach no longer has an account. Remove them and save again.';

  /// How the server's message for a missing user starts when it is the
  /// organizer; any other missing user of a staff save is a coach.
  static const String organizerNotFoundPrefix = 'Organizer';

  /// The status of a body that names something the server does not have.
  static const int notFoundStatus = 404;

  /// What the eligibility editor shows for [error], or `null` when the
  /// refusal names nothing the form holds (the host then reports a failed
  /// save).
  static EventFormRefusal? eligibilityRefusal(Object error) {
    if (error is! ServerException || error is StaleVersionException) {
      return null;
    }
    return switch (error.code) {
      SdkErrorCode.invalidState => (
        fieldErrors: const {},
        formError: invertedBandMessage,
      ),
      _ => null,
    };
  }

  /// What the organizer and coaches editor shows for [error], or `null`
  /// when the refusal names nothing the form holds (the host then reports
  /// a failed save).
  ///
  /// An organizer or a coach without an account shows on that field: the
  /// server answers both with `USER_NOT_FOUND` and tells them apart in its
  /// message. A From session a programme's split no longer accepts shows on
  /// the From field. A clash with another booking shows inline.
  static EventFormRefusal? staffRefusal(Object error) {
    if (error is! ServerException || error is StaleVersionException) {
      return null;
    }
    switch (error.code) {
      case SdkErrorCode.userNotFound when error.statusCode == notFoundStatus:
        final organizer = error.message.startsWith(organizerNotFoundPrefix);
        return (
          fieldErrors: organizer
              ? const {EventFormFields.organizerNameId: organizerGoneMessage}
              : const {EventFormFields.coachNamesId: coachGoneMessage},
          formError: null,
        );
      case SdkErrorCode.effectiveTimeNotSessionBoundary:
      case SdkErrorCode.cutoffTooSoon:
        return (
          fieldErrors: {
            EventFormFields.effectiveFromId: scheduleSaveErrorMessage(
              error,
              fallback: staffFromRefusedMessage,
            ),
          },
          formError: null,
        );
      case SdkErrorCode.conflict:
      case SdkErrorCode.timeConflict:
        return (fieldErrors: const {}, formError: staffClashMessage);
      default:
        return null;
    }
  }

  /// Shown on the From field when the server refuses the session and says
  /// no more.
  static const String staffFromRefusedMessage =
      'That session cannot be used. Pick another.';

  /// Shown inline when the organizer is booked elsewhere at the same time.
  static const String staffClashMessage =
      'That clashes with another booking of the organizer, a coach or the '
      'venue.';

  /// Organizer & coaches section.
  ///
  /// A camp's or a one-off's is an update: `organizerName` is a direct field
  /// (sending the trimmed value, possibly empty) and `coachNames` a
  /// clearable list.
  ///
  /// A programme's staffing changes by a split: one `updateEventForAllFuture`
  /// call effective from the session [values] hold under
  /// [EventFormFields.effectiveFromId], with [event]'s `version` and only
  /// what changed between the organizer and the coaches. Sessions before it
  /// keep the present staff. Returns [event] untouched, with no call, when
  /// neither changed.
  static Future<Event> updateOrganizer({
    required Event event,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) async {
    final coaches =
        (values[EventFormFields.coachNamesId] as List<String>?) ?? const [];
    final organizer =
        (values[EventFormFields.organizerNameId] as String?)?.trim() ?? '';
    if (event.type != EventType.programme) {
      return notifier.updateEvent(
        event.id,
        organizerName: organizer,
        coachNames: () => coaches,
      );
    }
    final organizerChanged = organizer != (event.organizerName?.trim() ?? '');
    final coachesChanged = !listEquals(
      coaches,
      event.coachNames ?? const <String>[],
    );
    if (!organizerChanged && !coachesChanged) return event;
    final from = values[EventFormFields.effectiveFromId] as DateTime;
    return notifier.updateEventForAllFuture(
      event.id,
      effectiveDateTimeUtc: from.toUtc(),
      version: event.version,
      organizerName: organizerChanged ? organizer : null,
      coachNames: coachesChanged ? () => coaches : null,
    );
  }

  /// Flags section — visibility + featured, persisted immediately on
  /// toggle: a correction of a programme, an update of a camp or a one-off.
  static Future<Event> updateFlags({
    required Event event,
    required ClEventsMasterNotifier notifier,
    Visibility? visibility,
    bool? isFeatured,
  }) {
    if (event.type == EventType.programme) {
      return notifier.correctionOnEvent(
        event.id,
        visibility: visibility,
        isFeatured: isFeatured,
      );
    }
    return notifier.updateEvent(
      event.id,
      visibility: visibility,
      isFeatured: isFeatured,
    );
  }
}
