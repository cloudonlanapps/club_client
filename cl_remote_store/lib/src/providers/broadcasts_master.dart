import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/notifications_master.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for admin-authored broadcasts.
///
/// Holds `Map<int, Broadcast>` newest-first by id. Only loads if the
/// current user has the admin role; non-admins get an empty map without
/// hitting the server (the broadcasts API would 403). Mutations:
///
///   * `sendText(text)` — convenience helper for the dashboard's inline
///     compose. Posts a `{v:1, type:'broadcast.text', data:{text}}`
///     payload to an `allUsers` audience with no expiry, then folds the
///     server's `Broadcast` into local state.
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
  @override
  Future<Map<int, Broadcast>> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isCoachOrAdmin) {
      return const <int, Broadcast>{};
    }
    ref.watch(clManualRefreshProvider);
    final client = await ref.watch(secureClientProvider.future);
    final page = await client.broadcasts.listBroadcasts();
    return {for (final b in page.items) b.id: b};
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Send a free-text broadcast to all users.
  ///
  /// Wraps the input in the server's payload envelope:
  /// `{v:1, type:'broadcast.text', data:{text}}`.
  /// When [email] is true the broadcast is also delivered by email using
  /// [emailSubject] as the subject and [text] as the (markdown) body; the
  /// caller is responsible for supplying a non-empty subject.
  /// Returns the server's [Broadcast] record so callers can show
  /// recipient counts immediately.
  Future<Broadcast> sendText(
    String text, {
    bool email = false,
    String? emailSubject,
  }) {
    return _send(
      const AudienceSelector.allUsers(),
      text,
      email: email,
      emailSubject: emailSubject,
    );
  }

  /// Send a free-text broadcast to the members of a single group.
  ///
  /// Identical to [sendText] but narrows the audience to the group's explicit
  /// members via `AudienceSelector.group`.
  Future<Broadcast> sendToGroup(
    int groupId,
    String text, {
    bool email = false,
    String? emailSubject,
  }) {
    return _send(
      AudienceSelector.group(groupId),
      text,
      email: email,
      emailSubject: emailSubject,
    );
  }

  Future<Broadcast> _send(
    AudienceSelector audienceSelector,
    String text, {
    required bool email,
    required String? emailSubject,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final created = await client.broadcasts.createBroadcast(
        audienceSelector: audienceSelector,
        payload: <String, dynamic>{
          'v': 1,
          'type': 'broadcast.text',
          'data': <String, dynamic>{'text': text},
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
    final current = state.valueOrNull;
    if (current == null) {
      state = AsyncData({b.id: b});
      return;
    }
    state = AsyncData({...current, b.id: b});
  }
}
