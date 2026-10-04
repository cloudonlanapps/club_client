import 'dart:async';

import 'package:cl_club_members/src/models/group_list_filter.dart';
import 'package:cl_club_members/src/providers/group_list.dart';
import 'package:cl_club_members/src/providers/group_list_filter.dart';
import 'package:cl_club_members/src/widgets/cards/group_card.dart';
import 'package:cl_club_members/src/widgets/group_filter_popover.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, LoadingView, TitleRow, isMobileWidth;

/// Admin/Coach group list content view with type filter, search, and
/// scrollable list.
///
/// **Permissions:** the wrapping screen (`GroupsScreen` in
/// `cl_member_zone`) enforces the admin/coach gate and supplies
/// [currentUser]. The view assumes a non-null current user with the
/// required role.
///
/// Does not include a Scaffold — the host provides the shell and routing.
class GroupListView extends ConsumerStatefulWidget {
  const GroupListView({
    required this.currentUser,
    required this.onGroupTap,
    required this.onCreateGroup,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final void Function(Group group) onGroupTap;
  final VoidCallback onCreateGroup;
  final VoidCallback? onBack;

  @override
  ConsumerState<GroupListView> createState() => GroupListViewState();
}

class GroupListViewState extends ConsumerState<GroupListView> {
  final scrollController = ScrollController();
  final searchController = TextEditingController();
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(groupListFilterProvider);
    searchController.text = initial.searchTerm ?? '';
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void updateFilter(GroupListFilter Function(GroupListFilter) mut) {
    final notifier = ref.read(groupListFilterProvider.notifier);
    notifier.state = mut(notifier.state);
  }

  bool get hasActiveFilters {
    final f = ref.read(groupListFilterProvider);
    return f.searchTerm != null ||
        f.typeFilter != GroupTypeFilter.all ||
        f.showDeleted;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.isCoachOrAdmin,
      'GroupListView called by a non-coach/admin user. '
      'GroupsScreen gate (isCoachOrAdmin) failed.',
    );
    final theme = ShadTheme.of(context);
    final isAdmin = widget.currentUser.isAdmin;
    final isMobile = isMobileWidth(context);
    final filter = ref.watch(groupListFilterProvider);
    final list = ref.watch(groupListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(title: 'Group Management', onBack: widget.onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: searchController,
                      placeholder: const Text('Search groups…'),
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (value) {
                        debounceTimer?.cancel();
                        debounceTimer = Timer(
                          const Duration(milliseconds: 400),
                          () {
                            updateFilter(
                              (f) => f.copyWith(
                                searchTerm: () => value.isEmpty ? null : value,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GroupFilterPopover(
                    filter: filter,
                    showDeletedToggle: isAdmin,
                    onFilterChanged: (updated) {
                      ref.read(groupListFilterProvider.notifier).state =
                          updated;
                    },
                  ),
                  const SizedBox(width: 8),
                  if (isMobile)
                    ActionIcon(
                      icon: Icons.group_add,
                      onPressed: widget.onCreateGroup,
                    )
                  else
                    ActionButton(
                      label: '+ Add group',
                      onPressed: widget.onCreateGroup,
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: list.when(
            loading: () => const LoadingView(),
            error: (e, _) => Center(
              child: Text(
                'Could not load groups: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No groups match the current filters.',
                    style: theme.textTheme.muted,
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        'Showing ${items.length} groups',
                        style: theme.textTheme.muted,
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(groupListProvider.notifier).refresh(),
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final group = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GroupCard(
                              key: ValueKey(group.id),
                              groupId: group.id,
                              onTap: () => widget.onGroupTap(group),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
