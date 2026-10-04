import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Member master provider for the user's My Events list.
///
/// Keyed by username. Holds the list returned by
/// `GET /v1/myevents/by_id/{username}` — the server is authoritative for
/// what belongs in this list:
///
///   * every event the user has an enrollment on (active or terminal —
///     grandfathered, so historical participation is preserved even if
///     current eligibility no longer matches);
///   * every public event the user is eligible for per the event's
///     structured criteria (`gender`, DOB bounds).
///
/// This provider intentionally performs no client-side eligibility
/// filtering on top of the server response — duplicating the rule would
/// risk diverging from the server and accidentally hide grandfathered
/// enrollments.
///
/// Watches occurrences version to rebuild when occurrences change.
final AutoDisposeAsyncNotifierProviderFamily<
  ClMyEventsMasterNotifier,
  List<Event>,
  String
>
clMyEventsMasterProvider = AsyncNotifierProvider.autoDispose
    .family<ClMyEventsMasterNotifier, List<Event>, String>(
      ClMyEventsMasterNotifier.new,
    );

/// Notifier for member's enrolled events (read-only list).
class ClMyEventsMasterNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Event>, String> {
  String get username => arg;

  @override
  Future<List<Event>> build(String arg) async {
    ref
      ..watch(
        clResourceVersionProvider.select((s) => s.occurrencesVersion),
      )
      ..watch(clManualRefreshProvider);
    final client = await ref.read(secureClientProvider.future);
    return fetchAllPages(
      ({required offset, required limit}) => client.myEvents.listMyEvents(
        username,
        limit: limit,
        offset: offset,
      ),
    );
  }
}
