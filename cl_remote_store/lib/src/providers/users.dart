import 'package:cl_remote_store/src/providers/users_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter key for user list queries.
///
/// Set fields to `null` to skip that filter. All filters are AND-combined.
typedef ClUsersFilter = ({
  String? role,
  UserStatus? status,
  String? searchTerm,
  bool excludeSuperAdmin,
});

/// Filtered user list provider.
///
/// Derives from [clUsersMasterProvider] with client-side filtering.
/// Replaces `coachListProvider`, `organizerListProvider`, and
/// `userListProvider`.
///
/// Example:
/// ```dart
/// // All coaches:
/// ref.watch(clUsersProvider(
///   (role: 'coach', status: null, searchTerm: null,
///    excludeSuperAdmin: true),
/// ));
///
/// // Active users matching search:
/// ref.watch(clUsersProvider(
///   (role: null, status: UserStatus.active, searchTerm: 'john',
///    excludeSuperAdmin: true),
/// ));
/// ```
final AutoDisposeFutureProviderFamily<List<UserInfo>, ClUsersFilter>
clUsersProvider = FutureProvider.autoDispose
    .family<List<UserInfo>, ClUsersFilter>(
      (ref, filter) async {
        final users = await ref.watch(clUsersMasterProvider.future);
        var result = users.values.toList();

        if (filter.excludeSuperAdmin) {
          result = result.where((u) => !u.isSuperAdmin).toList();
        }

        final role = filter.role;
        if (role != null) {
          result = result.where((u) => u.roles.hasRole(role)).toList();
        }

        final status = filter.status;
        if (status != null) {
          result = result.where((u) => u.status == status).toList();
        }

        final searchTerm = filter.searchTerm;
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final lower = searchTerm.toLowerCase();
          result = result
              .where(
                (u) =>
                    u.username.toLowerCase().contains(lower) ||
                    u.displayName.toLowerCase().contains(lower),
              )
              .toList();
        }

        return result;
      },
    );
