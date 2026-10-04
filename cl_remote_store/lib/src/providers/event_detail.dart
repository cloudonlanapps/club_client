import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single event detail, keyed by event ID.
///
/// Derives from [clEventsMasterProvider] — selects a single event from
/// the master map. Throws if the event is not in the master.
final AutoDisposeFutureProviderFamily<Event, int> clEventDetailProvider =
    FutureProvider.autoDispose.family<Event, int>((ref, eventId) async {
      final events = await ref.watch(clEventsMasterProvider.future);
      final event = events[eventId];
      if (event == null) {
        throw StateError('Event $eventId not found in master');
      }
      return event;
    });
