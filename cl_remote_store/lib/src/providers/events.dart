import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter key for event list queries.
typedef ClEventsFilter = ({
  EventType? eventType,
  Visibility? visibility,
  String? searchTerm,
  bool includePast,
});

/// Filtered event list provider.
///
/// Derives from [clEventsMasterProvider] with client-side filtering.
/// Replaces `eventListProvider`.
///
/// Example:
/// ```dart
/// // Active programmes only:
/// ref.watch(clEventsProvider(
///   (eventType: EventType.programme, visibility: null,
///    searchTerm: null, includePast: false),
/// ));
/// ```
final AutoDisposeFutureProviderFamily<List<Event>, ClEventsFilter>
clEventsProvider = FutureProvider.autoDispose
    .family<List<Event>, ClEventsFilter>(
      (ref, filter) async {
        final events = await ref.watch(clEventsMasterProvider.future);
        // Exclude soft-deleted events — the master map can hold an inactive
        // event right after a soft-delete (the notifier stores the server's
        // echoed entity instead of dropping the id).
        var result = events.values.where((e) => e.isActive).toList();

        final eventType = filter.eventType;
        if (eventType != null) {
          result = result.where((e) => e.type == eventType).toList();
        }

        final visibility = filter.visibility;
        if (visibility != null) {
          result = result.where((e) => e.visibility == visibility).toList();
        }

        if (!filter.includePast) {
          result = result.where((e) => e.status == EventStatus.active).toList();
        }

        final searchTerm = filter.searchTerm;
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final lower = searchTerm.toLowerCase();
          result = result
              .where((e) => e.title.toLowerCase().contains(lower))
              .toList();
        }

        return result;
      },
    );
