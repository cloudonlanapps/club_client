import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The end-date mutations of `ClEventsMasterNotifier`, for programmes: set
/// an end ([terminate]), move it ([extend]) and remove it
/// ([extendIndefinitely]) (club_client#39).
///
/// Each replaces the event in the master map with the server's answer and
/// reloads the occurrence feeds, since sessions at or after the end stop
/// occurring. A failure that may have reached the server reloads the events
/// and the feeds (club_core#138).
mixin ClEventsEndDateMutations on AsyncNotifier<Map<int, Event>> {
  /// Replace or add an event in the master map.
  void replaceLocally(Event event);

  /// Bump the occurrences version counter, so every occurrence feed reloads.
  void bumpOccurrencesVersion();

  /// Reload the events and occurrence feeds after an uncertain write.
  void refetchAfterUncertainWrite();

  /// Give a programme that has no end one, at [cutoffTimeUtc]: sessions at
  /// or after it do not occur, and the programme runs until then.
  ///
  /// [cutoffTimeUtc] must be a session start of the programme's current
  /// schedule, at least 30 minutes ahead. The server requires [reason].
  Future<Event> terminate(
    int eventId, {
    required String reason,
    required DateTime cutoffTimeUtc,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.events.terminate(
        eventId,
        reason: reason,
        cutoffTimeUtc: cutoffTimeUtc,
      );
      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Move a programme's end, while it is still ahead, to [cutoffTimeUtc],
  /// earlier or later, under the same rule as [terminate].
  Future<Event> extend(
    int eventId, {
    required DateTime cutoffTimeUtc,
    String? reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.events.extend(
        eventId,
        cutoffTimeUtc: cutoffTimeUtc,
        reason: reason,
      );
      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Remove a programme's end, while it is still ahead, so it runs
  /// open-ended again.
  Future<Event> extendIndefinitely(int eventId, {String? reason}) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.events.extendIndefinitely(
        eventId,
        reason: reason,
      );
      replaceLocally(updated);
      bumpOccurrencesVersion();
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }
}
