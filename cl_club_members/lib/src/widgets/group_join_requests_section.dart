import 'package:cl_club_members/src/views/group_join_requests_view.dart'
    show
        GroupJoinRequestsView,
        JoinRequestRow,
        RejectReasonDialog,
        kRejectCancelled;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupRequestsMasterProvider, writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/member_write_messages.dart';

/// Persistent "New Requests" section for the group profile view.
///
/// Always rendered for admin/coach viewers of a semi-auto group: it
/// surfaces pending join requests inline with approve / reject actions
/// and shows an explicit empty state when there are none. Replaces the
/// "Manage requests" overflow entry so admins don't have to chase a
/// menu to see what's waiting on them.
///
/// Reuses [JoinRequestRow] from the standalone
/// [GroupJoinRequestsView] so row styling and busy semantics stay in
/// sync between the two surfaces.
class GroupJoinRequestsSection extends ConsumerStatefulWidget {
  const GroupJoinRequestsSection({
    required this.groupId,
    super.key,
  });

  final int groupId;

  @override
  ConsumerState<GroupJoinRequestsSection> createState() =>
      GroupJoinRequestsSectionState();
}

class GroupJoinRequestsSectionState
    extends ConsumerState<GroupJoinRequestsSection> {
  /// Per-row busy flag so buttons disable while a mutation is in flight.
  final Set<int> _inFlight = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final requestsAsync = ref.watch(
      clGroupRequestsMasterProvider(widget.groupId),
    );

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Requests', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          requestsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Could not load requests: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (requests) {
              final pending =
                  requests.values
                      .where((r) => r.status == JoinRequestStatus.pending)
                      .toList()
                    ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

              if (pending.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No pending requests',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < pending.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    JoinRequestRow(
                      request: pending[i],
                      busy: _inFlight.contains(pending[i].id),
                      onApprove: () => _approve(pending[i].id),
                      onReject: () => _reject(pending[i].id),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _approve(int requestId) async {
    setState(() => _inFlight.add(requestId));
    try {
      await ref
          .read(clGroupRequestsMasterProvider(widget.groupId).notifier)
          .approve(requestId);
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Request approved.')),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(_messageForApprove(e)),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.approveRequestFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _inFlight.remove(requestId));
    }
  }

  Future<void> _reject(int requestId) async {
    final reason = await showShadDialog<String?>(
      context: context,
      builder: (_) => const RejectReasonDialog(),
    );
    if (reason == kRejectCancelled) return;
    setState(() => _inFlight.add(requestId));
    try {
      await ref
          .read(clGroupRequestsMasterProvider(widget.groupId).notifier)
          .reject(
            requestId,
            reason: (reason != null && reason.trim().isNotEmpty)
                ? reason.trim()
                : null,
          );
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Request rejected.')),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not reject: ${e.message}'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.rejectRequestFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _inFlight.remove(requestId));
    }
  }

  String _messageForApprove(ServerException e) {
    switch (e.code) {
      case SdkErrorCode.notEligible:
        return 'No longer eligible for this group.';
      case SdkErrorCode.alreadyMember:
        return 'User is already a member.';
      default:
        return 'Could not approve: ${e.message}';
    }
  }
}
