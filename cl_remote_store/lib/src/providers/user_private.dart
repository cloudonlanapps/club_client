import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/users_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only provider for a user's private profile.
///
/// Rebuilds when the user master changes (e.g., after updateUser).
/// Fetches full private profile from server on demand.
final AutoDisposeFutureProviderFamily<UserPrivate, String>
clUserPrivateProvider = FutureProvider.autoDispose.family<UserPrivate, String>(
  (ref, username) async {
    // Watch master so this rebuilds after user mutations.
    ref
      ..watch(clUsersMasterProvider)
      ..watch(clManualRefreshProvider);
    final client = await ref.read(secureClientProvider.future);
    return client.users.getUserPrivate(username);
  },
);
