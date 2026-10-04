import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../utils/member_write_messages.dart';

/// Resolves admin / coach actions for a single group row.
///
/// Active groups: `[Manage Members]` (only when the group allows manual
/// membership and a manage-members callback is wired; otherwise no actions).
/// Deleted groups: `[Restore]`.
///
/// Whole-group edit and delete are not surfaced on the row — group editing
/// is section-wise on the group profile, and deletion lives there too.
///
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`.
class AdminGroupActions extends ConsumerStatefulWidget {
  const AdminGroupActions({
    required this.group,
    required this.builder,
    this.onManageMembers,
    super.key,
  });

  final Group group;
  final VoidCallback? onManageMembers;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`).
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<AdminGroupActions> createState() => AdminGroupActionsState();
}

class AdminGroupActionsState extends ConsumerState<AdminGroupActions> {
  String? _running;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _resolve());
  }

  List<ActionItem> _resolve() {
    if (!widget.group.isActive) {
      return [
        ActionItem(
          label: 'Restore',
          loading: _running == 'restore',
          onPressed: _running != null ? null : _restore,
        ),
      ];
    }

    final isManual = widget.group.kind != GroupKind.auto;
    return [
      if (isManual && widget.onManageMembers != null)
        ActionItem(
          label: 'Manage Members',
          onPressed: _running == null ? widget.onManageMembers : null,
        ),
    ];
  }

  Future<void> _restore() => _runAction('restore', () async {
    await ref
        .read(clGroupsMasterProvider.notifier)
        .restoreGroup(widget.group.id);
  });

  Future<void> _runAction(String key, Future<void> Function() run) async {
    setState(() => _running = key);
    try {
      await run();
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(e.message)),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(e, fallback: MemberWriteMessages.actionFailed),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }
}
