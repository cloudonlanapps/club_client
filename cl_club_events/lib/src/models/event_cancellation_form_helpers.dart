import 'package:cl_club_forms/cl_club_forms.dart'
    show EventCancellationFormFields, EventCancellationSession;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';

/// SDK ↔ `EventCancellationForm` adapter (club_client#40).
///
/// The form is SDK-free in `ui_lib`; this helper owns the translation both
/// ways: [buildEventCancellationSessions] (occurrences → the sessions the
/// form offers) and [EventCancellationFormSubmit] (form → SDK).

/// The sessions of event [eventId] a camp cancellation may start from, out
/// of [occurrences], earliest first: those not yet completed whose slot is
/// more than the server's 30-minute lead ([attendanceOpenLeadIn]) after
/// [now].
///
/// A session is identified by its slot (`originalStartTimeUtc`), which is
/// what the server's cancel takes; it reads as the time it actually starts.
List<EventCancellationSession> buildEventCancellationSessions(
  Iterable<Occurrence> occurrences, {
  required int eventId,
  required DateTime now,
}) {
  final upcoming =
      occurrences
          .where(
            (o) =>
                o.eventId == eventId &&
                o.status != OccurrenceStatus.completed &&
                o.originalStartTimeUtc
                    .subtract(attendanceOpenLeadIn)
                    .isAfter(now),
          )
          .toList()
        ..sort(
          (a, b) => a.originalStartTimeUtc.compareTo(b.originalStartTimeUtc),
        );
  return [
    for (final o in upcoming)
      EventCancellationSession(
        start: o.originalStartTimeUtc,
        label: o.actualStartTimeUtc.toLocalDateTimeMedium(),
      ),
  ];
}

/// Bridges `EventCancellationForm` to the SDK's cancel and drop calls.
class EventCancellationFormSubmit {
  const EventCancellationFormSubmit._();

  /// Cancels the camp [eventId] from the session the form's [values] name,
  /// with their reason.
  static Future<Event> cancelCamp({
    required int eventId,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    return notifier.cancelSeries(
      eventId,
      reason: values[EventCancellationFormFields.reasonId] as String,
      effectiveDateTimeUtc:
          values[EventCancellationFormFields.fromSessionId] as DateTime,
    );
  }

  /// Calls the one-off [eventId] off with the reason in the form's
  /// [values]. [occurrenceVersion] is the version of the one-off's single
  /// occurrence as loaded, which the server asks for.
  static Future<Event> callOff({
    required int eventId,
    required int occurrenceVersion,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) {
    return notifier.drop(
      eventId,
      version: occurrenceVersion,
      reason: values[EventCancellationFormFields.reasonId] as String,
    );
  }
}
