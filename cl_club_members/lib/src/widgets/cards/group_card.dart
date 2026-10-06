import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import 'actions/admin_group_actions.dart';
import 'actions/user_group_actions.dart';

/// List-row card for a single group.
///
/// Caller passes only [groupId], an optional [username], and navigation
/// callbacks. The card resolves the [Group] from the appropriate master
/// (admin or member-side), derives its own status caption, and mounts
/// the right action resolver internally.
///
/// Data sourcing:
///   * `username == null` → admin lens. Group resolved from
///     `clGroupsMasterProvider`. Trailing = [AdminGroupActions].
///   * `username != null` → user lens. Group resolved from
///     `clMyGroupsMasterProvider(username)` ∪ `clMyEligibleGroupsProvider`
///     (falls back to admin master if neither carries it — happens when
///     a join-request row references a group the user is not currently in
///     and not eligible to join). Trailing = [UserGroupActions].
///
/// Pass [trailing] to override the resolved trailing actions — used by
/// surfaces with bespoke actions (e.g. admin removing a target user from
/// a manual group on the user profile).
class GroupCard extends ConsumerWidget {
  const GroupCard({
    required this.groupId,
    this.username,
    this.onTap,
    this.onManageMembers,
    this.trailing,
    this.memberEligible = true,
    super.key,
  });

  final int groupId;

  /// Target user whose perspective this row represents. `null` → admin.
  final String? username;

  final VoidCallback? onTap;

  /// Admin perspective only. Navigation to a manage-members screen.
  /// Optional today — most surfaces don't expose this yet.
  final VoidCallback? onManageMembers;

  /// Replaces the internally-resolved trailing actions with a caller-supplied
  /// typed list. Used by surfaces that need a bespoke action (e.g. admin
  /// removing a target user from a group on the user profile, or
  /// approve / reject on pending join requests). Flows through
  /// [EntityCard.trailingActions], so it gets the same mobile reflow.
  final List<ActionItem>? trailing;

  /// False when the row stands for one member's place in the group and the
  /// server reports that member as no longer meeting the group's criteria:
  /// the meta line then carries the shared mark (club_client#43).
  final bool memberEligible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = _resolveGroup(ref);
    if (group == null) {
      return EntityCard(
        image: EntityImage.placeholder(),
        title: 'Group #$groupId',
        onTap: onTap,
      );
    }

    final caption = _captionFor(ref, group);
    final imageUrl = ref.watch(groupImageProvider(group.id)).value;
    final headers = ref.watch(imageAuthHeadersProvider).value ?? const {};
    final image = imageUrl != null
        ? EntityImage.network(imageUrl, httpHeaders: headers)
        : EntityImage.placeholder();
    EntityCard card(List<ActionItem> actions) => EntityCard(
      image: image,
      title: group.name,
      caption: caption,
      body: GroupMetaLine(group: group, memberEligible: memberEligible),
      trailingActions: actions.isEmpty ? null : actions,
      onTap: onTap,
    );

    // Caller-supplied bespoke actions take precedence over the resolved set.
    if (trailing != null) return card(trailing!);

    if (username == null) {
      return AdminGroupActions(
        group: group,
        onManageMembers: onManageMembers,
        builder: (context, actions) => card(actions),
      );
    }
    return UserGroupActions(
      group: group,
      username: username!,
      builder: (context, actions) => card(actions),
    );
  }

  Group? _resolveGroup(WidgetRef ref) {
    if (username == null) {
      return ref.watch(clGroupsMasterProvider).valueOrNull?[groupId];
    }
    final mine = ref.watch(clMyGroupsMasterProvider(username!)).valueOrNull;
    final inMine = mine?.where((g) => g.id == groupId).firstOrNull;
    if (inMine != null) return inMine;
    final eligible = ref
        .watch(clMyEligibleGroupsProvider(username!))
        .valueOrNull;
    final inEligible = eligible?.where((g) => g.id == groupId).firstOrNull;
    if (inEligible != null) return inEligible;
    // Last-ditch fallback: admin master (might not be loaded for member
    // surfaces but harmless if absent).
    return ref.watch(clGroupsMasterProvider).valueOrNull?[groupId];
  }

  String? _captionFor(WidgetRef ref, Group group) {
    if (username == null) return null;
    final requests = ref
        .watch(clMyJoinRequestsMasterProvider(username!))
        .valueOrNull;
    // Only surface a live (pending) request as the card's caption.
    // Terminal rows (cancelled/rejected/approved) describe past
    // attempts; the group is back in `eligible` and the card is now
    // joinable — a "Cancelled" caption on a joinable card is misleading.
    final myRequest = requests?.values
        .where(
          (r) => r.groupId == groupId && r.status == JoinRequestStatus.pending,
        )
        .firstOrNull;
    return myRequest == null ? null : _requestStatusText(myRequest);
  }

  static String _requestStatusText(JoinRequest r) {
    switch (r.status) {
      case JoinRequestStatus.pending:
        return 'Request sent — pending review';
      case JoinRequestStatus.approved:
        return 'Approved';
      case JoinRequestStatus.rejected:
        final reason = r.reason;
        return (reason != null && reason.isNotEmpty)
            ? 'Rejected: $reason'
            : 'Rejected';
      case JoinRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// The card's meta line: the group's age sentence (when it has an age band),
/// its kind and, for a member who no longer matches it, the shared mark.
class GroupMetaLine extends StatelessWidget {
  const GroupMetaLine({
    required this.group,
    this.memberEligible = true,
    super.key,
  });

  final Group group;

  /// False adds the shared no-longer-eligible mark to the line.
  final bool memberEligible;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fg = theme.colorScheme.mutedForeground;
    final style = theme.textTheme.muted;

    final ageSentence = AgeEligibilityText.sentence(
      minAge: formAgeFromSdk(group.minAge),
      maxAge: formAgeFromSdk(group.maxAge),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        if (ageSentence != null)
          IconText(
            icon: LucideIcons.cake,
            text: ageSentence,
            color: fg,
            style: style,
          ),
        StatusBadge(label: group.kind.label),
        if (!memberEligible) const NoLongerEligibleLabel(),
      ],
    );
  }
}

class IconText extends StatelessWidget {
  const IconText({
    required this.icon,
    required this.text,
    required this.color,
    required this.style,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
