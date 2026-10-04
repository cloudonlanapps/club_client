import 'package:cl_club_members/src/providers/user_list_filter.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clRegisteredUsersProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Snapshot of a filtered user list.
@immutable
class UserListState {
  const UserListState({
    required this.items,
    required this.total,
  });

  final List<UserInfo> items;
  final int total;

  UserListState copyWith({
    List<UserInfo>? items,
    int? total,
  }) {
    return UserListState(
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }
}

/// Status sort priority: pending first, then active, blocked, left.
const Map<UserStatus, int> statusSortOrder = {
  UserStatus.pending: 0,
  UserStatus.active: 1,
  UserStatus.blocked: 2,
  UserStatus.left: 3,
};

/// Applies standard post-processing to a user list:
/// - Excludes superAdmin users
/// - Sorts by status priority (pending → active → blocked → left),
///   then by display name within each status group
///
/// Used by both [userListProvider] and example app overrides to ensure
/// consistent ordering without duplicating logic.
List<UserInfo> applyUserListPostProcessing(List<UserInfo> users) {
  final filtered = users.where((u) => !u.isSuperAdmin).toList()
    ..sort((a, b) {
      // Primary: status priority
      final statusCmp = (statusSortOrder[a.status] ?? 9).compareTo(
        statusSortOrder[b.status] ?? 9,
      );
      if (statusCmp != 0) return statusCmp;

      // Secondary: by display name (full name)
      final cmp = a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
      return cmp;
    });

  return filtered;
}

/// Filterable list of users derived from [clUsersMasterProvider].
///
/// Watches [clUsersMasterProvider] for the canonical data and
/// [userListFilterProvider] for the active filter. All filtering, searching,
/// and sorting happens client-side.
///
/// SuperAdmin users are excluded and the list is sorted by status priority
/// via [applyUserListPostProcessing].
final userListProvider = AsyncNotifierProvider<UserListNotifier, UserListState>(
  UserListNotifier.new,
);

class UserListNotifier extends AsyncNotifier<UserListState> {
  @override
  Future<UserListState> build() async {
    final filter = ref.watch(userListFilterProvider);
    // `registered` users are never in the master list (nor the server's
    // default list), so that filter reads them on their own (#91).
    final users = filter.status == UserStatus.registered
        ? await ref.watch(clRegisteredUsersProvider.future)
        : (await ref.watch(clUsersMasterProvider.future)).values.toList();
    final filtered = _applyFilter(users, filter);
    return UserListState(items: filtered, total: filtered.length);
  }

  /// Re-fetch all user data from the server.
  Future<void> refresh() async {
    ref
      ..invalidate(clUsersMasterProvider)
      ..invalidate(clRegisteredUsersProvider);
  }

  List<UserInfo> _applyFilter(List<UserInfo> users, UserListFilter filter) {
    var result = users.toList();

    // Status filter
    if (filter.status != null) {
      result = result.where((u) => u.status == filter.status).toList();
    }

    // Role filter
    if (filter.role != null) {
      result = result.where((u) => u.roles.hasRole(filter.role!)).toList();
    }

    // Search filter
    final search = filter.searchTerm;
    if (search != null && search.isNotEmpty) {
      result = result.where((u) => _matchesSearch(u, search)).toList();
    }

    // Post-process: exclude superAdmin + sort by status priority
    return applyUserListPostProcessing(result);
  }

  bool _matchesSearch(UserInfo user, String term) {
    final lower = term.toLowerCase();
    return user.username.toLowerCase().contains(lower) ||
        user.displayName.toLowerCase().contains(lower) ||
        (user.firstName?.toLowerCase().contains(lower) ?? false) ||
        (user.lastName?.toLowerCase().contains(lower) ?? false);
  }
}
