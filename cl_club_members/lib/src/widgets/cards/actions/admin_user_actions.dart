import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../utils/member_write_messages.dart';

/// Resolves admin / coach actions for a single user row.
///
/// Actions are status-driven:
///   active   → (none — destructive actions live on the user's profile)
///   pending  → `[Review]`
///   blocked  → `[Unblock, ⋮ Delete]`
///   left     → `[Reactivate, ⋮ Delete]`
///
/// For pending users, lifecycle actions other than Review (approve, block,
/// delete) live on the user's profile screen — Review takes the admin there.
/// Active rows expose no actions; the row tap-through reaches the profile,
/// which already gates Block / Delete behind a confirm-then-act flow.
///
/// Coaches and non-admins see no actions — only the row tap-through.
///
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`. Mutations run on `clUsersMasterProvider` with a
/// single `_running` flag gating concurrent presses.
class AdminUserActions extends ConsumerStatefulWidget {
  const AdminUserActions({
    required this.username,
    required this.builder,
    this.onReview,
    super.key,
  });

  final String username;

  /// Invoked when the admin presses **Review** on a pending row — opens
  /// the user's profile. When `null`, the Review action is omitted.
  final VoidCallback? onReview;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`).
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<AdminUserActions> createState() => AdminUserActionsState();
}

class AdminUserActionsState extends ConsumerState<AdminUserActions> {
  /// Key of the mutation currently in flight; `null` when idle.
  String? _running;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _resolve());
  }

  List<ActionItem> _resolve() {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    if (actingUser == null || !actingUser.isAdmin) return const [];
    final user = ref.watch(clUsersMasterProvider).valueOrNull?[widget.username];
    if (user == null) return const [];

    final busy = _running != null;
    switch (user.status) {
      case UserStatus.pending:
        return [
          if (widget.onReview != null)
            ActionItem(
              label: 'Review',
              onPressed: busy ? null : widget.onReview,
            ),
        ];
      case UserStatus.blocked:
        return [
          ActionItem(
            label: 'Unblock',
            loading: _running == 'unblock',
            onPressed: busy
                ? null
                : () => _run('unblock', () => _master.unblockUser(_username)),
          ),
          _deleteAction(),
        ];
      case UserStatus.left:
        return [
          ActionItem(
            label: 'Reactivate',
            loading: _running == 'reactivate',
            onPressed: busy
                ? null
                : () => _run(
                    'reactivate',
                    () => _master.reactivateUser(_username),
                  ),
          ),
          _deleteAction(),
        ];
      // Defensive — admins have nothing actionable until the user submits
      // for review. `registered` users are filtered out of admin lists in
      // `clUsersMasterProvider`; this arm covers per-user lookup paths.
      case UserStatus.active || UserStatus.registered:
        return const [];
    }
  }

  ActionItem _deleteAction() => ActionItem(
    label: 'Delete',
    destructive: true,
    loading: _running == 'delete',
    onPressed: _running != null ? null : _confirmDelete,
  );

  String get _username => widget.username;
  ClUsersMasterNotifier get _master => ref.read(clUsersMasterProvider.notifier);

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete user?',
      message: 'This will soft-delete @$_username. They can be restored later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run('delete', () => _master.deleteUser(_username));
  }

  Future<void> _run(String key, Future<void> Function() mutate) async {
    setState(() => _running = key);
    try {
      await mutate();
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
