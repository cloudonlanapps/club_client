import 'package:cl_club_members/src/widgets/cards/group_card.dart'
    show GroupCard;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clMyEligibleGroupsProvider,
        clMyGroupsMasterProvider,
        clMyJoinRequestsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

/// Member-facing "My Groups" view.
///
/// Lists IDs only — the [GroupCard] resolves each group itself from the
/// member-side providers (mine / eligible / join-requests) and derives
/// its own status caption. This view never reads enrollment / request
/// state directly for display; it only reads the lists to know which IDs
/// to show.
class MyGroupsView extends ConsumerWidget {
  const MyGroupsView({
    required this.username,
    this.onGroupTap,
    this.onBack,
    super.key,
  });

  /// The user whose groups we are viewing. Authorization (self, admin,
  /// coach) is enforced server-side; the calling screen is responsible
  /// for not constructing this view for the wrong viewer.
  final String username;

  /// Invoked when the viewer taps a group card. The router supplies this
  /// to navigate to `/memberzone/my-groups/:username/:groupId`.
  final ValueChanged<int>? onGroupTap;

  /// Supplied by the wrapping screen: pops the route when poppable (deep-link
  /// entry), `null` when reached via the sidebar (no back button).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final auth = ref.watch(authStateProvider);
    if (auth.valueOrNull == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(title: 'My Groups', onBack: onBack),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CurrentMembershipsSection(
                  username: username,
                  theme: theme,
                  onGroupTap: onGroupTap,
                ),
                const SizedBox(height: 16),
                JoinableAndRequestsSection(
                  username: username,
                  theme: theme,
                  onGroupTap: onGroupTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CurrentMembershipsSection extends ConsumerWidget {
  const CurrentMembershipsSection({
    required this.username,
    required this.theme,
    this.onGroupTap,
    super.key,
  });

  final String username;
  final ShadThemeData theme;
  final ValueChanged<int>? onGroupTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mineAsync = ref.watch(clMyGroupsMasterProvider(username));
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Current memberships',
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          mineAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Could not load your groups: $e',
              style: theme.textTheme.muted,
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return Text(
                  'You are not a member of any group yet.',
                  style: theme.textTheme.muted,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final g in groups) ...[
                    GroupCard(
                      key: ValueKey('mine-${g.id}'),
                      groupId: g.id,
                      username: username,
                      onTap: onGroupTap == null
                          ? null
                          : () => onGroupTap!(g.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class JoinableAndRequestsSection extends ConsumerWidget {
  const JoinableAndRequestsSection({
    required this.username,
    required this.theme,
    this.onGroupTap,
    super.key,
  });

  final String username;
  final ShadThemeData theme;
  final ValueChanged<int>? onGroupTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibleAsync = ref.watch(clMyEligibleGroupsProvider(username));
    final requestsAsync = ref.watch(clMyJoinRequestsMasterProvider(username));

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Joinable groups & my requests',
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (eligibleAsync.isLoading || requestsAsync.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildBody(
              eligible: eligibleAsync.valueOrNull ?? const <Group>[],
              requests: requestsAsync.valueOrNull ?? const <int, JoinRequest>{},
            ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required List<Group> eligible,
    required Map<int, JoinRequest> requests,
  }) {
    // This section is sourced from the `eligible` list, which the server
    // returns as the set of groups the member may currently join — including
    // ones they already have a pending request for (flagged `requested`).
    // Each eligible group renders exactly once:
    //   - no pending request  → a joinable "Request to Join" card;
    //   - a pending request    → a "Cancel Request" card.
    // Rendering both a joinable card (from `eligible`) and a request card
    // (from `requests`) for the same group is what double-rendered it before
    // (issue #649) — so the joinable rows exclude groups with a pending
    // request, and request rows are limited to groups still present in
    // `eligible`. A pending request whose group has dropped out of `eligible`
    // (criteria tightened, or group deleted) is intentionally not shown here:
    // its fate is the admin's to decide.
    final pendingRequests = [
      for (final r in requests.values)
        if (r.status == JoinRequestStatus.pending) r,
    ]..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    final pendingGroupIds = {for (final r in pendingRequests) r.groupId};
    final eligibleIds = {for (final g in eligible) g.id};

    final joinable = [
      for (final g in eligible)
        if (!pendingGroupIds.contains(g.id)) g,
    ];
    final shownRequests = [
      for (final r in pendingRequests)
        if (eligibleIds.contains(r.groupId)) r,
    ];

    if (joinable.isEmpty && shownRequests.isEmpty) {
      return Text(
        'No groups to join. Looking for a specific one? Ask an admin to '
        'add criteria or invite you directly.',
        style: theme.textTheme.muted,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in joinable) ...[
          GroupCard(
            key: ValueKey('joinable-${g.id}'),
            groupId: g.id,
            username: username,
            onTap: onGroupTap == null ? null : () => onGroupTap!(g.id),
          ),
          const SizedBox(height: 8),
        ],
        for (final r in shownRequests) ...[
          GroupCard(
            key: ValueKey('request-${r.id}'),
            groupId: r.groupId,
            username: username,
            onTap: onGroupTap == null ? null : () => onGroupTap!(r.groupId),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
