import 'package:cl_remote_store/src/models/broadcast_scope.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:cl_remote_store/src/utils/writes_during_load.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for admin-authored broadcasts.
///
/// Holds `Map<int, Broadcast>` newest-first by id. Only loads if the
/// current user has the admin role; non-admins get an empty map without
/// hitting the server (the broadcasts API would 403). Mutations:
///
///   * `send(scope:, audience:, text:)` — posts a `broadcast.text` payload
///     carrying the Broadcast screen's [BroadcastScope] as `source` to any
///     audience, with no expiry, then folds the server's `Broadcast` into
///     local state. [clBroadcastsForScopeProvider] lists one screen's.
///   * `revoke(id)` — soft-revoke; replaces the local entry with the
///     server's updated `Broadcast` (status `revoked`).
///
/// Per CLAUDE.md "Centralized Resource State Management", this is the
/// only caller of `BroadcastSource` outside `cl_member_auth`.
final AsyncNotifierProvider<ClBroadcastsMasterNotifier, Map<int, Broadcast>>
clBroadcastsMasterProvider =
    AsyncNotifierProvider<ClBroadcastsMasterNotifier, Map<int, Broadcast>>(
      ClBroadcastsMasterNotifier.new,
    );

class ClBroadcastsMasterNotifier extends AsyncNotifier<Map<int, Broadcast>> {
  final _writes = WritesDuringLoad<int, Broadcast>();

  @override
  Future<Map<int, Broadcast>> build() => _writes.load(() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isAdmin) {
      return const <int, Broadcast>{};
    }
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final items = await fetchAllPages(client.broadcasts.listBroadcasts);
    return {for (final b in items) b.id: b};
  });

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Send a free-text broadcast to [audience] from the Broadcast screen of
  /// [scope] (club_client#252).
  ///
  /// Wraps the input in the server's payload envelope,
  /// `{v:1, type:'broadcast.text', data:{text}, source}`, where `source` is
  /// [BroadcastScope.toPayload]: the screen's sent list reads it back
  /// ([BroadcastScope.lists]), since a narrowed [audience] (a `users` list)
  /// does not name the group or event.
  ///
  /// When [email] is true the broadcast is also delivered by email using
  /// [emailSubject] as the subject and [text] as the (markdown) body; the
  /// caller is responsible for supplying a non-empty subject.
  /// Returns the server's [Broadcast] record so callers can show
  /// recipient counts immediately.
  Future<Broadcast> send({
    required BroadcastScope scope,
    required AudienceSelector audience,
    required String text,
    bool email = false,
    String? emailSubject,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.broadcasts.createBroadcast(
        audienceSelector: audience,
        payload: <String, dynamic>{
          'v': 1,
          'type': 'broadcast.text',
          'data': <String, dynamic>{'text': text},
          BroadcastScope.payloadKey: scope.toPayload(),
        },
        email: email,
        emailSubject: email ? emailSubject : null,
        emailBody: email ? text : null,
      );
      _replaceLocally(created);
      // The server fans the broadcast out as one notification per recipient,
      // including the sender themselves. Invalidate the notifications feed so
      // the admin sees their own announcement without restarting the app.
      ref.invalidate(clNotificationsMasterProvider);
      return created;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Revoke a broadcast. The server preserves the row for audit and
  /// returns it with `status = revoked`; we fold that into local state.
  Future<Broadcast> revoke(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.broadcasts.revokeBroadcast(id);
      _replaceLocally(updated);
      // Revoke deletes the recipient notification rows server-side; refresh
      // so the admin's notifications list stops showing the revoked entry.
      ref.invalidate(clNotificationsMasterProvider);
      return updated;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// After a send or revoke that may have landed
  /// ([refetchIfWriteUncertain]): reload the broadcasts and the
  /// notifications they fan out to.
  void refetchAfterUncertainWrite() {
    ref
      ..invalidateSelf()
      ..invalidate(clNotificationsMasterProvider);
  }

  void _replaceLocally(Broadcast b) {
    final next = _writes.put(state.valueOrNull, b.id, b);
    if (next != null) state = AsyncData(next);
  }
}

/// The broadcasts the Broadcast screen of a [BroadcastScope] lists
/// ([BroadcastScope.lists]), newest first, revoked ones included
/// (club_client#252). Derived from [clBroadcastsMasterProvider]: the
/// server's list has no audience filter.
final AutoDisposeProviderFamily<AsyncValue<List<Broadcast>>, BroadcastScope>
clBroadcastsForScopeProvider = Provider.autoDispose
    .family<AsyncValue<List<Broadcast>>, BroadcastScope>(
      (ref, scope) => ref
          .watch(clBroadcastsMasterProvider)
          .whenData(
            (map) =>
                map.values.where(scope.lists).toList()
                  ..sort((a, b) => b.sentAtUtc.compareTo(a.sentAtUtc)),
          ),
    );
