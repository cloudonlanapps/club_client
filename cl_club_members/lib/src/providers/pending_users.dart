import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending users (status == [UserStatus.pending]) derived from
/// [clUsersMasterProvider]. SuperAdmin users are excluded.
final pendingUsersProvider = Provider<AsyncValue<List<UserInfo>>>((ref) {
  final master = ref.watch(clUsersMasterProvider);
  return master.whenData(
    (users) => users.values
        .where((u) => !u.isSuperAdmin && u.status == UserStatus.pending)
        .toList(),
  );
});

/// Count of pending users; 0 while loading or on error.
final pendingUsersCountProvider = Provider<int>((ref) {
  return ref
      .watch(pendingUsersProvider)
      .maybeWhen(
        data: (users) => users.length,
        orElse: () => 0,
      );
});
