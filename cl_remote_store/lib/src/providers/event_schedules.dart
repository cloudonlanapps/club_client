import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches an event's timetable: its sequence of [EventSchedule]s, oldest
/// first (club_server#384, club_core#16). A camp or one-off has one; a
/// programme gains one per split.
///
/// Watches only what of its own event a schedule carries
/// ([_EventScheduleInputs]), so a save of anything else on the event (its
/// title, visibility, description, gallery, …) does not read the schedules
/// again (club_client#230). A save that corrects an older schedule's
/// timetable invalidates this provider itself.
final FutureProviderFamily<List<EventSchedule>, int> clEventSchedulesProvider =
    FutureProvider.family<List<EventSchedule>, int>((ref, eventId) async {
      ref
        ..watch(
          clEventsMasterProvider.select(
            (s) => _EventScheduleInputs.of(s.valueOrNull?[eventId]),
          ),
        )
        ..watch(clManualRefreshProvider);
      final client = await ref.read(secureClientProvider.future);
      return client.events.listSchedules(eventId);
    });

/// The fields of an [Event] its schedules carry: a change to any of them
/// (a reschedule, a split, a timetable correction, a cutoff) changes what
/// `listSchedules` returns. Compared by value, lists included.
@immutable
class _EventScheduleInputs {
  const _EventScheduleInputs._({
    required this.loaded,
    this.startTimeUtc,
    this.endTimeUtc,
    this.rrule,
    this.venueId,
    this.organizerName,
    this.coachNames,
    this.sessions,
    this.untilTimeUtc,
  });

  /// The inputs of [event]; `null` (not loaded, or gone) has none.
  factory _EventScheduleInputs.of(Event? event) => event == null
      ? const _EventScheduleInputs._(loaded: false)
      : _EventScheduleInputs._(
          loaded: true,
          startTimeUtc: event.startTimeUtc,
          endTimeUtc: event.endTimeUtc,
          rrule: event.rrule,
          venueId: event.venueId,
          organizerName: event.organizerName,
          coachNames: event.coachNames,
          sessions: event.sessions,
          untilTimeUtc: event.untilTimeUtc,
        );

  final bool loaded;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final String? rrule;
  final int? venueId;
  final String? organizerName;
  final List<String>? coachNames;
  final List<EventSession>? sessions;
  final DateTime? untilTimeUtc;

  @override
  bool operator ==(Object other) =>
      other is _EventScheduleInputs &&
      other.loaded == loaded &&
      other.startTimeUtc == startTimeUtc &&
      other.endTimeUtc == endTimeUtc &&
      other.rrule == rrule &&
      other.venueId == venueId &&
      other.organizerName == organizerName &&
      listEquals(other.coachNames, coachNames) &&
      listEquals(other.sessions, sessions) &&
      other.untilTimeUtc == untilTimeUtc;

  @override
  int get hashCode => Object.hash(
    loaded,
    startTimeUtc,
    endTimeUtc,
    rrule,
    venueId,
    organizerName,
    coachNames == null ? null : Object.hashAll(coachNames!),
    sessions == null ? null : Object.hashAll(sessions!),
    untilTimeUtc,
  );
}
