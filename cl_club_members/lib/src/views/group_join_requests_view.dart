import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clGroupRequestsMasterProvider,
        clGroupsMasterProvider,
        clUsersMasterProvider,
        writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../utils/member_write_messages.dart';

/// Admin/coach triage view for join requests on a single group.
///
/// Lists every request on the group regardless of status, with a free-text
/// search over the requester's username and reason. Pending requests are
/// surfaced first; historical entries follow by recency. Approve / Reject
/// are enabled only for `pending` rows.
///
/// **Permissions:** the wrapping screen (`GroupJoinRequestsScreen` in
/// `cl_member_zone`) enforces the admin/coach gate and supplies
/// [currentUser]. The view assumes a non-null current user with the
/// required role.
class GroupJoinRequestsView extends ConsumerStatefulWidget {
  const GroupJoinRequestsView({
    required this.currentUser,
    required this.groupId,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final int groupId;
  final VoidCallback? onBack;

  @override
  ConsumerState<GroupJoinRequestsView> createState() =>
      GroupJoinRequestsViewState();
}

class GroupJoinRequestsViewState extends ConsumerState<GroupJoinRequestsView> {
  /// Per-row busy flag so the buttons disable on the row in flight.
  final Set<int> inFlight = <int>{};
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final requestsAsync = ref.watch(
      clGroupRequestsMasterProvider(widget.groupId),
    );
    final groupName = ref
        .watch(clGroupsMasterProvider)
        .whenOrNull(data: (m) => m[widget.groupId]?.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupJoinRequestsHeader(
          groupName: groupName,
          searchTerm: searchTerm,
          onSearchChanged: (term) => setState(() => searchTerm = term),
          onBack: widget.onBack,
        ),
        const Divider(height: 1),
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Could not load requests: $e',
                style: theme.textTheme.muted,
              ),
            ),
            data: (requests) {
              final term = searchTerm.trim().toLowerCase();
              final filtered =
                  requests.values
                      .where(
                        (r) =>
                            term.isEmpty ||
                            r.username.toLowerCase().contains(term) ||
                            (r.reason?.toLowerCase().contains(term) ?? false),
                      )
                      .toList()
                    ..sort((a, b) {
                      // Pending first; then most recent.
                      final aPending = a.status == JoinRequestStatus.pending;
                      final bPending = b.status == JoinRequestStatus.pending;
                      if (aPending != bPending) return aPending ? -1 : 1;
                      return b.requestedAt.compareTo(a.requestedAt);
                    });

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    term.isEmpty
                        ? 'No join requests yet.'
                        : 'No requests match your search.',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    clGroupRequestsMasterProvider(widget.groupId),
                  );
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    return JoinRequestRow(
                      request: r,
                      busy: inFlight.contains(r.id),
                      onApprove: r.status == JoinRequestStatus.pending
                          ? () => approve(r.id)
                          : null,
                      onReject: r.status == JoinRequestStatus.pending
                          ? () => reject(r.id)
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> approve(int requestId) async {
    setState(() => inFlight.add(requestId));
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
      toastWriteFailure(e, MemberWriteMessages.approveRequestFailed);
    } finally {
      if (mounted) setState(() => inFlight.remove(requestId));
    }
  }

  Future<void> reject(int requestId) async {
    final reason = await showShadDialog<String?>(
      context: context,
      builder: (_) => const RejectReasonDialog(),
    );
    if (reason == kRejectCancelled) return;
    setState(() => inFlight.add(requestId));
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
      toastWriteFailure(e, MemberWriteMessages.rejectRequestFailed);
    } finally {
      if (mounted) setState(() => inFlight.remove(requestId));
    }
  }

  /// Toasts a failed write: [fallback], or that it is unconfirmed.
  void toastWriteFailure(Object e, String fallback) {
    ShadToaster.of(context).show(
      ShadToast.destructive(
        description: Text(writeFailureMessage(e, fallback: fallback)),
      ),
    );
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

/// Sentinel returned by [RejectReasonDialog] when the user cancels,
/// distinguished from an empty (no-reason-but-confirmed) submission.
const String kRejectCancelled = '__cancelled__';

class GroupJoinRequestsHeader extends StatelessWidget {
  const GroupJoinRequestsHeader({
    required this.groupName,
    required this.searchTerm,
    required this.onSearchChanged,
    this.onBack,
    super.key,
  });

  final String? groupName;
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(
          title: groupName ?? 'Join requests',
          subtitle: 'Join requests',
          onBack: onBack,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ShadInput(
            initialValue: searchTerm,
            placeholder: const Text('Search by username or reason…'),
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: onSearchChanged,
          ),
        ),
      ],
    );
  }
}

class JoinRequestRow extends ConsumerWidget {
  const JoinRequestRow({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  final JoinRequest request;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final users = ref.watch(clUsersMasterProvider).valueOrNull ?? const {};
    final displayName =
        users[request.username]?.displayName ?? request.username;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${request.username} · '
                  'Requested ${_fmt(request.requestedAt)} · '
                  '${request.status.name}',
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
                if (request.reason != null && request.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${request.reason}',
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (onApprove != null) ...[
            const SizedBox(width: 8),
            ShadButton(
              size: ShadButtonSize.sm,
              onPressed: busy ? null : onApprove,
              child: const Text('Approve'),
            ),
          ],
          if (onReject != null) ...[
            const SizedBox(width: 8),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: busy ? null : onReject,
              child: const Text('Reject'),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int msUtc) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
      msUtc,
      isUtc: true,
    ).toLocal();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class RejectReasonDialog extends StatefulWidget {
  const RejectReasonDialog({super.key});

  @override
  State<RejectReasonDialog> createState() => RejectReasonDialogState();
}

class RejectReasonDialogState extends State<RejectReasonDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Reject join request'),
      description: const Text(
        'Optionally include a reason. The user will see this on their request.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(kRejectCancelled),
          child: const Text('Cancel'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Reject'),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ShadInput(
          controller: controller,
          placeholder: const Text('Reason (optional)'),
          maxLines: 3,
        ),
      ),
    );
  }
}
