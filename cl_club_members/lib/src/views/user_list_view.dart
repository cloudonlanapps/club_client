import 'dart:async';

import 'package:cl_club_members/src/providers/user_list.dart';
import 'package:cl_club_members/src/providers/user_list_filter.dart';
import 'package:cl_club_members/src/widgets/cards/user_card.dart';
import 'package:cl_club_members/src/widgets/pending_approvals_banner.dart';
import 'package:cl_club_members/src/widgets/user_filter_popover.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionIcon, LoadingView, TitleRow, isMobileWidth;

/// Admin/Coach user list content view with status/role filters,
/// search, and scrollable list.
///
/// **Permissions:** the wrapping screen (`UsersScreen` in
/// `cl_member_zone`) enforces the admin/coach gate and supplies
/// [currentUser]. The view assumes a non-null current user with the
/// required role.
///
/// Does not include a Scaffold — the host provides the shell and routing.
/// Navigation is delegated via [onUserTap] and [onCreateUser] callbacks.
class UserListView extends ConsumerStatefulWidget {
  const UserListView({
    required this.currentUser,
    required this.onUserTap,
    required this.onReviewUser,
    required this.onCreateUser,
    required this.onActNow,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final void Function(UserInfo user) onUserTap;
  final void Function(UserInfo user) onReviewUser;
  final VoidCallback onCreateUser;
  final VoidCallback? onBack;

  /// Called when the admin taps "Act Now" on the pending approvals banner.
  /// Hosts wire this to the admin review surface.
  final VoidCallback onActNow;

  @override
  ConsumerState<UserListView> createState() => UserListViewState();
}

class UserListViewState extends ConsumerState<UserListView> {
  final scrollController = ScrollController();
  final searchController = TextEditingController();
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(userListFilterProvider);
    searchController.text = initial.searchTerm ?? '';
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void updateFilter(UserListFilter Function(UserListFilter) mut) {
    final notifier = ref.read(userListFilterProvider.notifier);
    notifier.state = mut(notifier.state);
  }

  bool get hasActiveFilters {
    final f = ref.read(userListFilterProvider);
    return f.status != null || f.role != null || f.searchTerm != null;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.isCoachOrAdmin,
      'UserListView called by a non-coach/admin user. '
      'UsersScreen gate (isCoachOrAdmin) failed.',
    );
    final theme = ShadTheme.of(context);
    final isAdmin = widget.currentUser.isAdmin;
    final isMobile = isMobileWidth(context);
    final filter = ref.watch(userListFilterProvider);
    final list = ref.watch(userListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(title: 'User Management', onBack: widget.onBack),
        if (isAdmin) PendingApprovalsBanner(onActNow: widget.onActNow),
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
                      placeholder: const Text('Search users…'),
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
                  UserFilterPopover(
                    filter: filter,
                    showStatusFilter: isAdmin,
                    onFilterChanged: (updated) {
                      ref.read(userListFilterProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 8),
                  if (isMobile)
                    ActionIcon(
                      icon: Icons.person_add,
                      enabled: isAdmin,
                      onPressed: widget.onCreateUser,
                    )
                  else
                    ActionButton(
                      label: '+ Add user',
                      enabled: isAdmin,
                      onPressed: widget.onCreateUser,
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
                'Could not load users: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (state) {
              // Admin: hide pending users (they're surfaced via the
              // PendingApprovalsBanner / AdminUserReviewView instead).
              // Coach: only show active users.
              final items = isAdmin
                  ? state.items
                        .where((u) => u.status != UserStatus.pending)
                        .toList()
                  : state.items
                        .where((u) => u.status == UserStatus.active)
                        .toList();

              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No users match the current filters.',
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
                        'Showing ${items.length} of ${state.total}',
                        style: theme.textTheme.muted,
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(userListProvider.notifier).refresh(),
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final user = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: UserCard(
                              key: ValueKey(user.username),
                              username: user.username,
                              user: user,
                              onTap: () => widget.onUserTap(user),
                              onReview: () => widget.onReviewUser(user),
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
