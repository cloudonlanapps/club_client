import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fetches an event's timetable: its sequence of [EventSchedule]s, oldest
/// first (club_server#384, club_core#16). A camp or one-off has one; a
/// programme gains one per split.
///
/// Watches [clEventsMasterProvider] to rebuild when events change.
final FutureProviderFamily<List<EventSchedule>, int> clEventSchedulesProvider =
    FutureProvider.family<List<EventSchedule>, int>((ref, eventId) async {
      // Watch master to rebuild if events change (e.g. after a split).
      ref
        ..watch(clEventsMasterProvider)
        ..watch(clManualRefreshProvider);
      final client = await ref.read(secureClientProvider.future);
      return client.events.listSchedules(eventId);
    });
