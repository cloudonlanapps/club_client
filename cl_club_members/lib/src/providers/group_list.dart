import 'package:cl_club_members/src/models/group_list_filter.dart';
import 'package:cl_club_members/src/providers/group_list_filter.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filterable list of groups derived from [clGroupsMasterProvider].
///
/// Watches [clGroupsMasterProvider] for the canonical data and
/// [groupListFilterProvider] for the active filter. All filtering and
/// searching happens client-side.
final groupListProvider = AsyncNotifierProvider<GroupListNotifier, List<Group>>(
  GroupListNotifier.new,
);

class GroupListNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
    final master = await ref.watch(clGroupsMasterProvider.future);
    final filter = ref.watch(groupListFilterProvider);
    return applyFilter(master.values.toList(), filter);
  }

  /// Re-fetch all group data from the server.
  Future<void> refresh() async {
    ref.invalidate(clGroupsMasterProvider);
  }

  List<Group> applyFilter(List<Group> groups, GroupListFilter filter) {
    var result = groups.toList();

    // Active vs deleted
    if (filter.showDeleted) {
      result = result.where((g) => !g.isActive).toList();
    } else {
      result = result.where((g) => g.isActive).toList();
    }

    // Type filter
    switch (filter.typeFilter) {
      case GroupTypeFilter.manual:
        result = result.where((g) => g.kind == GroupKind.manual).toList();
      case GroupTypeFilter.auto:
        result = result.where((g) => g.kind == GroupKind.auto).toList();
      case GroupTypeFilter.semiAuto:
        result = result.where((g) => g.kind == GroupKind.semiAuto).toList();
      case GroupTypeFilter.all:
        break;
    }

    // Search filter
    final search = filter.searchTerm;
    if (search != null && search.isNotEmpty) {
      final lower = search.toLowerCase();
      result = result.where((g) {
        return g.name.toLowerCase().contains(lower) ||
            (g.description?.toLowerCase().contains(lower) ?? false);
      }).toList();
    }

    // Sort alphabetically by name
    result.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return result;
  }
}
