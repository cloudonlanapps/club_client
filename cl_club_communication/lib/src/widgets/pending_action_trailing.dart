import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/notification_deep_link.dart';
import '../utils/notification_writes.dart';

/// Shown when a pending action fails with no more specific message.
const String pendingActionFailedMessage =
    'Could not complete the action. Please try again.';

/// Trailing widget for one row in the Pending Actions list.
///
/// Shape depends on the notification's [AppNotification.pendingActionType]:
///   * `groupJoinRequest`      → Approve / Reject
///   * `enrollmentOpportunity` → Accept / Decline
///   * `enrollmentRequest`     → Approve / Reject
///   * `attendanceCorrection`  → Open
///   * `userApproval`          → Review (#381 — admin acts inside
///                                AdminUserReviewView, no inline Approve)
///   * `userReconsider`        → Approve / Review (legacy; the
///                                user-side notification itself is being
///                                phased out via server #136)
///   * unknown                 → Open
///
/// Action handlers go through the relevant master notifier — never the
/// SDK directly. On success the row is removed via
/// [ClPendingActionsMasterNotifier.dismissLocally]; the server's
/// auto-dismiss reconciles on next refresh.
class PendingActionTrailing extends ConsumerStatefulWidget {
  const PendingActionTrailing({
    required this.notification,
    required this.currentUsername,
    required this.onOpen,
    super.key,
  });

  final AppNotification notification;
  final String currentUsername;

  /// Invoked when the user picks the inert "Open" action — the host
  /// navigates using the resolved [NotificationDeepLink].
  final void Function(NotificationDeepLink link) onOpen;

  @override
  ConsumerState<PendingActionTrailing> createState() =>
      _PendingActionTrailingState();
}

class _PendingActionTrailingState extends ConsumerState<PendingActionTrailing> {
  bool _busy = false;

  Map<String, dynamic> get _data {
    final raw = widget.notification.payload['data'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Whether [username] has no usable credit for this row's programme, so
  /// accepting or approving is greyed out with a 🪙 0 chip (club_core#97,
  /// #105). False for a camp or one-off, where the payload lacks the type,
  /// with credit off, or while unknown.
  bool isUnfunded(String username, int eventId) {
    if (_data['eventType'] != EventType.programme.name) return false;
    return ref.watch(
          clCreditUsableForEventProvider((
            username: username,
            eventId: eventId,
            trial: false,
          )),
        ) ==
        0;
  }

  /// Runs [body]; a refusal is toasted as [message] when given, otherwise
  /// as the server's message after [errorPrefix].
  Future<void> _run(
    Future<void> Function() body, {
    String? errorPrefix,
    String Function(ServerException)? message,
  }) async {
    setState(() => _busy = true);
    try {
      await body();
      ref
          .read(clPendingActionsMasterProvider.notifier)
          .dismissLocally(widget.notification.id);
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            message != null
                ? message(e)
                : errorPrefix != null
                ? '$errorPrefix: ${e.message}'
                : e.message,
          ),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      showWriteFailure(
        context,
        e,
        errorPrefix != null ? '$errorPrefix.' : pendingActionFailedMessage,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _approveRejectRow() {
    final groupId = _asInt(_data['groupId']);
    final requestId = widget.notification.pendingActionId;
    if (groupId == null || requestId == null) return _openButton();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadButton(
          size: ShadButtonSize.sm,
          onPressed: _busy
              ? null
              : () => _run(
                  () async {
                    await ref
                        .read(clGroupRequestsMasterProvider(groupId).notifier)
                        .approve(requestId);
                  },
                  errorPrefix: 'Could not approve',
                ),
          child: const Text('Approve'),
        ),
        const SizedBox(width: 6),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: _busy
              ? null
              : () => _run(
                  () async {
                    await ref
                        .read(clGroupRequestsMasterProvider(groupId).notifier)
                        .reject(requestId);
                  },
                  errorPrefix: 'Could not reject',
                ),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  Widget _acceptDeclineRow() {
    final eventId = _asInt(_data['eventId']);
    if (eventId == null) return _openButton();
    final key = (username: widget.currentUsername, eventId: eventId);
    final unfunded = isUnfunded(widget.currentUsername, eventId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unfunded) ...[
          CreditChip(username: widget.currentUsername, credits: 0),
          const SizedBox(width: 6),
        ],
        ShadButton(
          size: ShadButtonSize.sm,
          onPressed: _busy || unfunded
              ? null
              : () => _run(
                  () async {
                    await ref
                        .read(clMyEnrollmentsMasterProvider(key).notifier)
                        .acceptInvite();
                  },
                  errorPrefix: 'Could not accept',
                ),
          child: const Text('Accept'),
        ),
        const SizedBox(width: 6),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: _busy
              ? null
              : () => _run(
                  () async {
                    await ref
                        .read(clMyEnrollmentsMasterProvider(key).notifier)
                        .declineInvite();
                  },
                  errorPrefix: 'Could not decline',
                ),
          child: const Text('Decline'),
        ),
      ],
    );
  }

  Widget _approveRejectEnrollmentRow() {
    final eventId = _asInt(_data['eventId']);
    final memberUsername = _data['memberUsername'];
    if (eventId == null ||
        memberUsername is! String ||
        memberUsername.isEmpty) {
      return _openButton();
    }
    final unfunded = isUnfunded(memberUsername, eventId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unfunded) ...[
          CreditChip(username: memberUsername, credits: 0),
          const SizedBox(width: 6),
        ],
        ShadButton(
          size: ShadButtonSize.sm,
          onPressed: _busy || unfunded
              ? null
              : () => _run(
                  () async {
                    await ref
                        .read(clEnrollmentsMasterProvider(eventId).notifier)
                        .approveRequest(memberUsername);
                  },
                  message: enrollmentApproveErrorMessage,
                ),
          child: const Text('Approve'),
        ),
        const SizedBox(width: 6),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: _busy
              ? null
              : () => _run(
                  () async {
                    await ref
                        .read(clEnrollmentsMasterProvider(eventId).notifier)
                        .rejectRequest(memberUsername);
                  },
                  errorPrefix: 'Could not reject',
                ),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  Widget _openButton({String label = 'Open'}) {
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: _busy
          ? null
          : () {
              final link = resolveDeepLink(
                widget.notification,
                currentUsername: widget.currentUsername,
              );
              if (link != null) widget.onOpen(link);
            },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    switch (widget.notification.pendingActionType) {
      case PendingActionType.groupJoinRequest:
        return _approveRejectRow();
      case PendingActionType.enrollmentOpportunity:
        return _acceptDeclineRow();
      case PendingActionType.enrollmentRequest:
        return _approveRejectEnrollmentRow();
      case PendingActionType.userApproval:
        // #381: no inline Approve. The Review button opens
        // AdminUserReviewView where the admin chooses Approve /
        // Reconsider / Reject / Block with full context.
        return _openButton(label: 'Review');
      case PendingActionType.attendanceCorrection:
        return _openButton();
      case null:
        return _openButton();
    }
  }
}
