import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single event detail, keyed by event ID.
///
/// A synchronous select of [clEventsMasterProvider]'s entry for the event:
/// a write to the master (a section save, `replaceLocally`) arrives here as
/// data, never as a reload, so a page built on it keeps its state while one
/// section saves (club_client#229). The master's own loading and error pass
/// through. An event absent from the master is a
/// `StateError('Event X not found in master')`.
final AutoDisposeProviderFamily<AsyncValue<Event>, int> clEventDetailProvider =
    Provider.autoDispose.family<AsyncValue<Event>, int>((ref, eventId) {
      final entry = ref.watch(
        clEventsMasterProvider.select((s) => s.whenData((m) => m[eventId])),
      );
      return entry.whenData(
        (event) =>
            event ?? (throw StateError('Event $eventId not found in master')),
      );
    });
