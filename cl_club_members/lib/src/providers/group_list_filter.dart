import 'package:cl_club_members/src/models/group_list_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently active filter for `groupListProvider`.
///
/// Mutate via the StateProvider's notifier; the group list will reload.
final groupListFilterProvider = StateProvider<GroupListFilter>(
  (ref) => const GroupListFilter(),
);
