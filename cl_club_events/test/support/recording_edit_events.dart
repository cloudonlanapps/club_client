import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// The verb of a plain update, which the server offers to camps and
/// one-offs.
const String updateVerb = 'update';

/// The verb that corrects a programme for its whole life.
const String correctionVerb = 'correction';

/// The verb that changes a programme from a session onward.
const String splitVerb = 'split';

/// One write an editor sent: its verb and the terms it carried, by name,
/// those left out not listed.
typedef SentEdit = ({String verb, Map<String, Object?> terms});

/// Records which call each edit of [event] went through, and what it
/// carried; [refusal], when set, is thrown by each instead.
class RecordingEditEvents extends ClEventsMasterNotifier {
  RecordingEditEvents(this.event);

  final Event event;
  final List<SentEdit> sent = [];
  Exception? refusal;

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

  Event record(String verb, Map<String, Object?> terms) {
    sent.add((
      verb: verb,
      terms: {
        for (final term in terms.entries)
          if (term.value != null) term.key: term.value,
      },
    ));
    final refused = refusal;
    if (refused != null) throw refused;
    return event;
  }

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
  }) async => record(updateVerb, {
    'title': title,
    'description': description,
    'visibility': visibility,
    'isFeatured': isFeatured,
    'organizerName': organizerName,
    'coachNames': coachNames?.call(),
  });

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
  }) async => record(correctionVerb, {
    'title': title,
    'description': description,
    'visibility': visibility,
    'isFeatured': isFeatured,
  });

  @override
  Future<Event> updateEventForAllFuture(
    int eventId, {
    required DateTime effectiveDateTimeUtc,
    int? version,
    int? venueId,
    String? organizerName,
    List<String>? Function()? coachNames,
    DateTime? startTimeUtc,
    DateTime? endTimeUtc,
    String? rrule,
    List<EventSession>? Function()? sessions,
  }) async => record(splitVerb, {
    'effectiveDateTimeUtc': effectiveDateTimeUtc,
    'version': version,
    'venueId': venueId,
    'organizerName': organizerName,
    'coachNames': coachNames?.call(),
    'startTimeUtc': startTimeUtc,
    'rrule': rrule,
  });
}

/// Expects [events] to have sent one write: [verb], carrying [terms] and
/// nothing else.
void expectOneEdit(
  RecordingEditEvents events,
  String verb,
  Map<String, Object?> terms,
) {
  expect(events.sent, hasLength(1));
  expect(events.sent.single.verb, verb);
  expect(events.sent.single.terms, terms);
}
