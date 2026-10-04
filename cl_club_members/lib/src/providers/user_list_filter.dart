import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently active filter for `userListProvider`.
///
/// Mutate via the StateProvider's notifier; the user list will reload.
final userListFilterProvider = StateProvider<UserListFilter>(
  (ref) => const UserListFilter(),
);
