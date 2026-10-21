import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:cl_remote_store/src/utils/writes_during_load.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for the user's own join requests (any status).
///
/// Family-keyed by `username`. Holds the canonical
/// `Map<requestId, JoinRequest>` of every join request the user has
/// submitted. The `join` and `cancel` mutations on the master notifiers
/// update this state with the server response; no manual refetch is
/// needed.
final AsyncNotifierProviderFamily<
  ClMyJoinRequestsMasterNotifier,
  Map<int, JoinRequest>,
  String
>
clMyJoinRequestsMasterProvider =
    AsyncNotifierProvider.family<
      ClMyJoinRequestsMasterNotifier,
      Map<int, JoinRequest>,
      String
    >(
      ClMyJoinRequestsMasterNotifier.new,
    );

class ClMyJoinRequestsMasterNotifier
    extends FamilyAsyncNotifier<Map<int, JoinRequest>, String> {
  final _writes = WritesDuringLoad<int, JoinRequest>();

  @override
  Future<Map<int, JoinRequest>> build(String username) =>
      _writes.load(() async {
        ref.watch(clManualRefreshProvider);
        final client = await ref.watch(secureClientProvider.future);
        final requests = await client.myGroups.listMyRequests(username);
        return {for (final r in requests) r.id: r};
      });

  /// Cancel a still-pending join request. Replaces local state with
  /// the server's updated [JoinRequest] (status `cancelled`).
  Future<JoinRequest> cancel(int requestId) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.myGroups.cancelRequest(arg, requestId);
      replaceLocally(updated);
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Public helper used by sibling notifiers (e.g.
  /// `clMyGroupsMasterProvider.join`) to fold a newly created request
  /// into local state.
  void replaceLocally(JoinRequest request) {
    final next = _writes.put(state.valueOrNull, request.id, request);
    if (next != null) state = AsyncData(next);
  }
}
