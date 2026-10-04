import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The occurrence mutations of `ClEventsMasterNotifier`: reschedule, cancel
/// and undo-cancel one occurrence of an event.
///
/// Each change sends the occurrence's own `version` (`Occurrence.version`, as
/// last loaded; club_core#69). A stale one is refused with
/// [StaleVersionException]; the occurrences are then reloaded before it is
/// rethrown, so the caller can say who changed it and when.
mixin ClEventsOccurrenceMutations on AsyncNotifier<Map<int, Event>> {
  /// Bump the occurrences version counter, so every occurrence feed reloads.
  void bumpOccurrencesVersion();

  Future<void> _changeOccurrence(Future<void> Function() change) async {
    try {
      // A change that may have landed reloads the occurrence feeds
      // (club_core#138).
      await refetchIfWriteUncertain(change, refetch: bumpOccurrencesVersion);
    } on StaleVersionException {
      bumpOccurrencesVersion();
      rethrow;
    }
    bumpOccurrencesVersion();
  }

  /// Reschedule a specific occurrence.
  ///
  /// A day is described by its start and duration; the server derives the end
  /// from start + [newDurationMinutes] (1–1440). At least one of
  /// [newStartTimeUtc], [newDurationMinutes], [newVenueId] must be supplied.
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
  }) async {
    final client = await ref.read(secureClientProvider.future);
    await _changeOccurrence(
      () => client.occurrences.rescheduleOccurrence(
        eventId,
        occurrenceTimeUtc,
        version: version,
        newStartTimeUtc: newStartTimeUtc,
        newDurationMinutes: newDurationMinutes,
        newVenueId: newVenueId,
      ),
    );
  }

  /// Cancel a specific occurrence.
  Future<void> cancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    required String reason,
  }) async {
    final client = await ref.read(secureClientProvider.future);
    await _changeOccurrence(
      () => client.occurrences.cancelOccurrence(
        eventId,
        occurrenceTimeUtc,
        version: version,
        reason: reason,
      ),
    );
  }

  /// Undo cancellation of a specific occurrence.
  Future<void> undoCancelOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
  }) async {
    final client = await ref.read(secureClientProvider.future);
    await _changeOccurrence(
      () => client.occurrences.undoCancelOccurrence(
        eventId,
        occurrenceTimeUtc,
        version: version,
      ),
    );
  }
}
