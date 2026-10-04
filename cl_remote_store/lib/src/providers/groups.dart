import 'package:cl_remote_store/src/providers/groups_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter key for group list queries.
typedef ClGroupsFilter = ({
  bool includeDeleted,
  String? typeFilter,
  String? searchTerm,
});

/// Filtered group list provider.
///
/// Derives from [clGroupsMasterProvider] with client-side filtering.
/// Replaces `activeGroupListProvider` and `groupListProvider`.
///
/// Example:
/// ```dart
/// // Active groups only:
/// ref.watch(clGroupsProvider(
///   (includeDeleted: false, typeFilter: null, searchTerm: null),
/// ));
/// ```
final AutoDisposeFutureProviderFamily<List<Group>, ClGroupsFilter>
clGroupsProvider = FutureProvider.autoDispose
    .family<List<Group>, ClGroupsFilter>(
      (ref, filter) async {
        final groups = await ref.watch(clGroupsMasterProvider.future);
        var result = groups.values.toList();

        if (!filter.includeDeleted) {
          result = result.where((g) => g.deletedAtUtc == null).toList();
        }

        // typeFilter is reserved for future group type categorization.
        // Currently Group model has no type field.

        final searchTerm = filter.searchTerm;
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final lower = searchTerm.toLowerCase();
          result = result
              .where(
                (g) => g.name.toLowerCase().contains(lower),
              )
              .toList();
        }

        return result;
      },
    );
