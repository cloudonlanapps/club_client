import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../utils/member_write_messages.dart';

/// Resolves user-perspective actions for a single group row.
///
/// Joinable groups (not yet a member, no pending request): `[Request to Join]`.
/// Groups with a pending request from this user: `[Cancel Request]`.
/// Groups the user already belongs to: no actions (member-self leave is
/// blocked on server-side issue #196; until it lands the user must ask an
/// admin to remove them).
///
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`. The list is empty for members (self-leave is blocked
/// server-side) and for auto groups.
class UserGroupActions extends ConsumerStatefulWidget {
  const UserGroupActions({
    required this.group,
    required this.username,
    required this.builder,
    super.key,
  });

  final Group group;
  final String username;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`).
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<UserGroupActions> createState() => UserGroupActionsState();
}

class UserGroupActionsState extends ConsumerState<UserGroupActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _resolve());
  }

  List<ActionItem> _resolve() {
    final mine = ref
        .watch(clMyGroupsMasterProvider(widget.username))
        .valueOrNull;
    final requests = ref
        .watch(clMyJoinRequestsMasterProvider(widget.username))
        .valueOrNull;

    final isMember = mine?.any((g) => g.id == widget.group.id) ?? false;
    if (isMember) return const [];

    final pending = requests?.values
        .where(
          (r) =>
              r.groupId == widget.group.id &&
              r.status == JoinRequestStatus.pending,
        )
        .firstOrNull;

    if (pending != null) {
      return [
        ActionItem(
          label: 'Cancel Request',
          loading: _busy,
          onPressed: _busy ? null : () => _cancel(pending.id),
        ),
      ];
    }

    if (widget.group.kind == GroupKind.auto) {
      // Auto groups are not joinable — server rejects.
      return const [];
    }

    return [
      ActionItem(
        label: 'Request to Join',
        loading: _busy,
        onPressed: _busy ? null : _requestToJoin,
      ),
    ];
  }

  Future<void> _requestToJoin() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clMyGroupsMasterProvider(widget.username).notifier)
          .join(widget.group.id);
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(_messageFor(e))),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.sendRequestFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(int requestId) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clMyJoinRequestsMasterProvider(widget.username).notifier)
          .cancel(requestId);
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('Could not cancel: ${e.message}'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(
              e,
              fallback: MemberWriteMessages.cancelRequestFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(ServerException e) {
    switch (e.code) {
      case SdkErrorCode.autoGroupNotJoinable:
        return 'This group is auto — members are added automatically.';
      case SdkErrorCode.notEligible:
        return "You don't meet this group's criteria.";
      default:
        return 'Could not send request: ${e.message}';
    }
  }
}
