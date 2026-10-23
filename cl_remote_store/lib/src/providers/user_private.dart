import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/users_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only provider for a user's private profile.
///
/// Follows the user's own entry in [clUsersMasterProvider], not the whole
/// master, so a write to another user leaves it alone (club_client#229).
/// When that entry is already a [UserPrivate] (what `updateUser`,
/// `createUser` and `restoreUser` put there) it is the answer and nothing is
/// fetched; otherwise the private profile is fetched from the server.
///
/// It is still a future: a view reading it passes
/// `skipLoadingOnReload: true` to `when`, so a save shows the old profile
/// until the new one is in, never a spinner.
final AutoDisposeFutureProviderFamily<UserPrivate, String>
clUserPrivateProvider = FutureProvider.autoDispose.family<UserPrivate, String>(
  (ref, username) async {
    ref.watch(clManualRefreshProvider);
    // The flag is part of the selection because `UserInfo ==` ignores the
    // private fields: a `UserInfo` and the `UserPrivate` that replaces it
    // can compare equal.
    final (entry, _) = ref.watch(
      clUsersMasterProvider.select((s) {
        final user = s.valueOrNull?[username];
        return (user, user is UserPrivate);
      }),
    );
    if (entry is UserPrivate) return entry;
    final client = await ref.watch(secureClientProvider.future);
    return client.users.getUserPrivate(username);
  },
);
