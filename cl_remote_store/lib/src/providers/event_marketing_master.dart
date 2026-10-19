import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The extended marketing block of one event, keyed by event id, for staff
/// (club_client#1): read for an admin or coach, written and removed by an
/// admin or the event's organizer.
///
/// An event with no block reads as an empty [EventMarketing] at
/// [EventMarketing.unwrittenVersion], the version its first write is made
/// at. Watch it only where `eventMarketingProvider` is `true`: the routes
/// answer 503 where the module is off.
final AsyncNotifierProviderFamily<
  ClEventMarketingMasterNotifier,
  EventMarketing,
  int
>
clEventMarketingMasterProvider =
    AsyncNotifierProvider.family<
      ClEventMarketingMasterNotifier,
      EventMarketing,
      int
    >(ClEventMarketingMasterNotifier.new);

/// Notifier owning one event's extended marketing block.
///
/// Every write sends the block version last loaded and replaces the state
/// with the server's answer. A stale version ([StaleVersionException])
/// reloads the block before it is rethrown, so the caller can say who
/// changed it; a failure that may have reached the server reloads it too
/// (club_core#138).
class ClEventMarketingMasterNotifier
    extends FamilyAsyncNotifier<EventMarketing, int> {
  /// The event whose block this is.
  int get eventId => arg;

  @override
  Future<EventMarketing> build(int arg) async {
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    try {
      return await client.eventMarketing.getEventMarketing(arg);
    } on ServerException catch (e) {
      if (e.code == SdkErrorCode.eventMarketingNotFound) {
        return const EventMarketing();
      }
      rethrow;
    }
  }

  /// The block version a write sends: the one loaded.
  Future<int> loadedVersion() async => (await future).version;

  /// Replaces the whole block with [marketing]; a field left `null` is
  /// cleared. Returns the stored block.
  Future<EventMarketing> save(EventMarketing marketing) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final version = await loadedVersion();
      final stored = await reloadOnStale(
        () => client.eventMarketing.setEventMarketing(
          eventId,
          marketing,
          version: version,
        ),
      );
      state = AsyncData(stored);
      return stored;
    }, refetch: ref.invalidateSelf);
  }

  /// Removes the block: the event then has none.
  Future<void> clear() {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final version = await loadedVersion();
      await reloadOnStale(() async {
        await client.eventMarketing.clearEventMarketing(
          eventId,
          version: version,
        );
        return const EventMarketing();
      });
      state = const AsyncData(EventMarketing());
    }, refetch: ref.invalidateSelf);
  }

  /// Runs [change]; a stale version reloads the block before it is
  /// rethrown.
  Future<EventMarketing> reloadOnStale(
    Future<EventMarketing> Function() change,
  ) async {
    try {
      return await change();
    } on StaleVersionException {
      ref.invalidateSelf();
      rethrow;
    }
  }
}
