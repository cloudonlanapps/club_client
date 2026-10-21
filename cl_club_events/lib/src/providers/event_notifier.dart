import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Family provider for event notifier.
/// Key is event ID - watches the master and extracts the event reactively.
final AutoDisposeAsyncNotifierProviderFamily<EventNotifier, Event, int>
eventNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<EventNotifier, Event, int>(EventNotifier.new);

/// A read-only view of a single event by ID.
///
/// Watches [clEventsMasterProvider] for reactive updates. It has no
/// mutation methods: each change of an event is a type-specific call on the
/// master notifier (`cancelSeries` for a camp, `terminate` for a programme,
/// `drop` for a one-off, …), so no caller sends one type's call for another
/// (club_client#188).
class EventNotifier extends AutoDisposeFamilyAsyncNotifier<Event, int> {
  /// Event ID is available via [arg] property from Riverpod family notifier.
  int get eventId => arg;

  @override
  Future<Event> build(int eventId) async {
    final master = await ref.watch(clEventsMasterProvider.future);
    final event = master[eventId];
    if (event != null) return event;
    // Not in master map — fetch via the master notifier so SDK access
    // stays in cl_remote_store.
    return ref.read(clEventsMasterProvider.notifier).getEvent(eventId);
  }
}
