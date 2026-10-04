import 'package:cl_club_members/src/views/group_join_requests_view.dart'
    show JoinRequestRow, RejectReasonDialog, kRejectCancelled;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupRequestsMasterProvider, writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/member_write_messages.dart';

/// Compact "Pending Requests" preview rendered above the group info card.
///
/// Returns an empty widget when there are no pending requests — the section
/// is hidden entirely rather than showing an empty state.
class GroupPendingRequestsCard extends ConsumerStatefulWidget {
  const GroupPendingRequestsCard({
    required this.groupId,
    required this.onOpenAll,
    this.previewLimit = 3,
    super.key,
  });

  final int groupId;
  final VoidCallback onOpenAll;
  final int previewLimit;

  @override
  ConsumerState<GroupPendingRequestsCard> createState() =>
      GroupPendingRequestsCardState();
}

class GroupPendingRequestsCardState
    extends ConsumerState<GroupPendingRequestsCard> {
  final Set<int> _inFlight = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final requestsAsync = ref.watch(
      clGroupRequestsMasterProvider(widget.groupId),
    );

    final pendingCount = requestsAsync.maybeWhen(
      data: (requests) => requests.values
          .where((r) => r.status == JoinRequestStatus.pending)
          .length,
      orElse: () => 0,
    );

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Pending Requests', style: theme.textTheme.h4),
              const SizedBox(width: 8),
              if (pendingCount > 0)
                Text('($pendingCount)', style: theme.textTheme.muted),
              const Spacer(),
              if (pendingCount > 0)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    onPressed: widget.onOpenAll,
                    icon: Icon(
                      LucideIcons.squareArrowOutUpRight,
                      size: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    tooltip: 'View all requests',
                    iconSize: 14,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
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
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No pending requests.',
                    style: theme.textTheme.muted,
                  ),
                );
              }
              final preview = pending.take(widget.previewLimit).toList();
              final remaining = pending.length - preview.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < preview.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    JoinRequestRow(
                      request: preview[i],
                      busy: _inFlight.contains(preview[i].id),
                      onApprove: () => _approve(preview[i].id),
                      onReject: () => _reject(preview[i].id),
                    ),
                  ],
                  if (remaining > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '+ $remaining more',
                      style: theme.textTheme.muted,
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
          description: Text(_approveMessage(e)),
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

  String _approveMessage(ServerException e) {
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
