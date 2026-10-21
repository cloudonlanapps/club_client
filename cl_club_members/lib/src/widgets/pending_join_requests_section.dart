import 'package:cl_club_members/src/utils/join_request_decisions.dart';
import 'package:cl_club_members/src/widgets/cards/group_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyJoinRequestsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

/// Lists groups for which [username] has an outstanding pending join
/// request, with admin Approve / Reject actions per row. Renders nothing
/// when the viewer is not an admin or when there are no pending requests
/// — the section is fully self-suppressing.
class PendingJoinRequestsSection extends ConsumerStatefulWidget {
  const PendingJoinRequestsSection({
    required this.username,
    this.showCard = true,
    super.key,
  });

  final String username;
  final bool showCard;

  @override
  ConsumerState<PendingJoinRequestsSection> createState() =>
      PendingJoinRequestsSectionState();
}

class PendingJoinRequestsSectionState
    extends ConsumerState<PendingJoinRequestsSection> {
  final Set<int> inFlight = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final auth = ref.watch(authStateProvider).valueOrNull;
    if (!(auth?.isAdmin ?? false)) return const SizedBox.shrink();

    final requestsAsync = ref.watch(
      clMyJoinRequestsMasterProvider(widget.username),
    );

    if (requestsAsync.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ShadCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Loading pending join requests…',
            style: theme.textTheme.muted,
          ),
        ),
      );
    }
    if (requestsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: ShadCard(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Could not load pending join requests: ${requestsAsync.error}',
            style: theme.textTheme.muted,
          ),
        ),
      );
    }

    final pending =
        requestsAsync.valueOrNull?.values
            .where((r) => r.status == JoinRequestStatus.pending)
            .toList(growable: false) ??
        const <JoinRequest>[];
    if (pending.isEmpty) return const SizedBox.shrink();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending Join Requests', style: theme.textTheme.h4),
        const SizedBox(height: 4),
        Text(
          'Groups this user has requested to join.',
          style: theme.textTheme.muted,
        ),
        const SizedBox(height: 12),
        Column(
          children: pending.map((r) {
            final busy = inFlight.contains(r.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GroupCard(
                groupId: r.groupId,
                username: widget.username,
                trailing: [
                  ActionItem(
                    label: 'Approve',
                    onPressed: busy ? null : () => approve(r),
                  ),
                  ActionItem(
                    label: 'Reject',
                    onPressed: busy ? null : () => reject(r),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );

    final body = widget.showCard
        ? ShadCard(padding: const EdgeInsets.all(20), child: content)
        : content;
    return Padding(padding: const EdgeInsets.only(top: 20), child: body);
  }

  Future<void> approve(JoinRequest r) => approveJoinRequest(
    context,
    groupId: r.groupId,
    requestId: r.id,
    onBusy: (busy) => setBusy(r.id, busy: busy),
  );

  Future<void> reject(JoinRequest r) => rejectJoinRequest(
    context,
    groupId: r.groupId,
    requestId: r.id,
    onBusy: (busy) => setBusy(r.id, busy: busy),
  );

  /// Marks request [requestId] in flight, or no longer.
  void setBusy(int requestId, {required bool busy}) => setState(
    () => busy ? inFlight.add(requestId) : inFlight.remove(requestId),
  );
}
