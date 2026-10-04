import 'dart:async';

import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEnrollmentsMasterNotifier,
        clCreditUsableForEventProvider,
        clEnrollmentsMasterProvider,
        clEventCreditRosterProvider,
        clEventsMasterProvider,
        creditSystemProvider,
        enrollmentApproveErrorMessage,
        enrollmentRemoveErrorMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../../../utils/event_write_error_message.dart';
import '../../enrollment_confirmation_dialog.dart';

/// Resolves an admin's actions on one enrollment row (club_core#96, #105).
///
/// | status              | actions                         |
/// |---------------------|---------------------------------|
/// | `requested`         | `[Approve, Reject]`             |
/// | `withdrawRequested` | `[Approve, Reject]` (withdrawal)|
/// | active              | `[Remove]`                      |
/// | other               | (none)                          |
///
/// On a programme with credit on, an action the server would refuse is
/// greyed out up front with a [CreditChip] beside it as the reason:
/// - **Approve** a request when the member has no usable credit for the
///   programme (R35);
/// - **Approve** a withdrawal, or **Remove**, while credit is still bound to
///   the programme (`boundCredits` on the roster, R71): it is settled first
///   in the member's credit view, which the chip opens.
///
/// A refusal that slips past (a stale snapshot) is caught and toasted.
class AdminEnrollmentActions extends ConsumerStatefulWidget {
  const AdminEnrollmentActions({
    required this.eventId,
    required this.username,
    required this.status,
    required this.displayName,
    required this.builder,
    super.key,
  });

  final int eventId;
  final String username;
  final EnrollmentStatus status;
  final String displayName;

  /// Receives the resolved actions; typically wraps them in an ActionGroup.
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<AdminEnrollmentActions> createState() =>
      AdminEnrollmentActionsState();
}

class AdminEnrollmentActionsState
    extends ConsumerState<AdminEnrollmentActions> {
  /// The action in flight, by key; null when idle.
  String? running;

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(
      clEventsMasterProvider.select(
        (s) => s.valueOrNull?[widget.eventId]?.type,
      ),
    );
    final gated =
        type == EventType.programme && ref.watch(creditSystemProvider) == true;
    return widget.builder(context, resolve(gated: gated));
  }

  List<ActionItem> resolve({required bool gated}) {
    switch (widget.status) {
      case EnrollmentStatus.requested:
        final usable = gated
            ? ref.watch(
                clCreditUsableForEventProvider((
                  username: widget.username,
                  eventId: widget.eventId,
                  trial: false,
                )),
              )
            : null;
        return [
          item(
            'Approve',
            'approve',
            approveRequest,
            blockedBy: usable == 0 ? 0 : null,
          ),
          item('Reject', 'reject', rejectRequest),
        ];
      case EnrollmentStatus.withdrawRequested:
        return [
          item(
            'Approve',
            'approve_withdraw',
            approveWithdraw,
            blockedBy: boundCredits(gated: gated),
          ),
          item('Reject', 'reject_withdraw', rejectWithdraw),
        ];
      case EnrollmentStatus.assigned ||
          EnrollmentStatus.accepted ||
          EnrollmentStatus.assignedTrial:
        return [
          item(
            'Remove',
            'remove',
            remove,
            destructive: true,
            blockedBy: boundCredits(gated: gated),
          ),
        ];
      case EnrollmentStatus.invited ||
          EnrollmentStatus.rejected ||
          EnrollmentStatus.declined ||
          EnrollmentStatus.withdrawn ||
          EnrollmentStatus.removed:
        return const [];
    }
  }

  /// Credit still bound to the programme for this member, when it blocks a
  /// departure; null when nothing is bound or it is not known.
  int? boundCredits({required bool gated}) {
    if (!gated) return null;
    final row = ref
        .watch(clEventCreditRosterProvider(widget.eventId))
        .valueOrNull?[widget.username];
    final bound = row?.boundCredits ?? 0;
    return bound > 0 ? bound : null;
  }

  /// An action; greyed out, with a chip showing [blockedBy] credits as the
  /// reason, when [blockedBy] is not null. [run] asks for any confirmation
  /// first and shows [key] as loading only while the call is in flight.
  ActionItem item(
    String label,
    String key,
    Future<void> Function() run, {
    bool destructive = false,
    int? blockedBy,
  }) {
    final blocked = blockedBy != null;
    return ActionItem(
      label: label,
      loading: running == key,
      destructive: destructive,
      onPressed: running != null || blocked ? null : () => unawaited(run()),
      reason: blocked
          ? (_) => CreditChip(username: widget.username, credits: blockedBy)
          : null,
    );
  }

  ClEnrollmentsMasterNotifier get master =>
      ref.read(clEnrollmentsMasterProvider(widget.eventId).notifier);

  Future<void> approveRequest() => wrap(
    'approve',
    () => master.approveRequest(widget.username),
    message: enrollmentApproveErrorMessage,
  );

  Future<void> approveWithdraw() =>
      wrap('approve_withdraw', () => master.approveWithdraw(widget.username));

  Future<void> rejectRequest() async {
    final reason = await showEnrollmentConfirmationDialog(
      context,
      title: 'Reject Request',
      description: 'Reject join request from ${widget.displayName}?',
      showReasonField: true,
      confirmLabel: 'Reject',
    );
    if (reason == null) return;
    await wrap(
      'reject',
      () => master.rejectRequest(
        widget.username,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  Future<void> rejectWithdraw() async {
    final reason = await showEnrollmentConfirmationDialog(
      context,
      title: 'Reject Withdrawal',
      description: 'Reject withdrawal request from ${widget.displayName}?',
      showReasonField: true,
      confirmLabel: 'Reject',
    );
    if (reason == null) return;
    await wrap(
      'reject_withdraw',
      () => master.rejectWithdraw(
        widget.username,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  Future<void> remove() async {
    final reason = await showEnrollmentConfirmationDialog(
      context,
      title: 'Remove Enrollment',
      description: 'Remove ${widget.displayName} from this event?',
      showReasonField: true,
      confirmLabel: 'Remove',
    );
    if (reason == null) return;
    await wrap(
      'remove',
      () => master.removeEnrollment(
        widget.username,
        reason: reason.isEmpty ? null : reason,
      ),
      message: enrollmentRemoveErrorMessage,
    );
  }

  /// Runs [run] with [key] shown as loading; a refusal is toasted through
  /// [message] (the shared enrollment mapping unless an action names its
  /// own).
  Future<void> wrap(
    String key,
    Future<void> Function() run, {
    String Function(ServerException) message = mapEnrollmentMutationError,
  }) async {
    setState(() => running = key);
    try {
      await run();
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(message(e)),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(eventWriteErrorMessage(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => running = null);
    }
  }
}
