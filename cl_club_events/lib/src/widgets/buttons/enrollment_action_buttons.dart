import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionGroup, ActionItem;

import '../../utils/event_write_error_message.dart';

/// Composition widget that renders the appropriate enrollment action
/// buttons based on the user's enrollment status for an event.
///
/// For event-level contexts (no occurrence). For occurrence-level
/// contexts that also need attendance buttons, use `MemberActionButtons`.
///
/// Host widget: owns its own `_running` flag and calls
/// `clMyEnrollmentsMasterProvider` mutation methods directly (the project's
/// standard action pattern — see `cl_remote_store/CLAUDE.md`).
class EnrollmentActionButtons extends ConsumerStatefulWidget {
  const EnrollmentActionButtons({
    required this.username,
    required this.eventId,
    super.key,
  });

  final String username;
  final int eventId;

  @override
  ConsumerState<EnrollmentActionButtons> createState() =>
      EnrollmentActionButtonsState();
}

class EnrollmentActionButtonsState
    extends ConsumerState<EnrollmentActionButtons> {
  /// Key of the mutation currently in flight; `null` when idle.
  String? _running;

  String get _username => widget.username;
  int get _eventId => widget.eventId;

  @override
  Widget build(BuildContext context) {
    final enrollmentAsync = ref.watch(
      clMyEnrollmentProvider((username: _username, eventId: _eventId)),
    );
    final eventAsync = ref.watch(
      clMyEventDetailProvider((username: _username, eventId: _eventId)),
    );
    final actingUser = ref.watch(authStateProvider).valueOrNull;

    // Member self-service stays self-service: staff viewing another
    // member's event see its status, not the member's buttons
    // (club_core#127).
    if (actingUser == null || actingUser.username != _username) {
      return const SizedBox.shrink();
    }

    return enrollmentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (enrollment) => eventAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (event) => _buildButtons(enrollment, event, actingUser),
      ),
    );
  }

  Widget _buildButtons(
    Enrollment? enrollment,
    Event event,
    UserPrivate actingUser,
  ) {
    final canEnroll = canEnrollOnEvent(event, actingUser);
    // On a programme, no usable credit greys out Request to Join and
    // Accept, with a 🪙 0 chip beside them (club_core#97).
    final unfunded =
        event.type == EventType.programme &&
        ref.watch(
              clCreditUsableForEventProvider((
                username: _username,
                eventId: _eventId,
                trial: enrollment?.isTrial ?? false,
              )),
            ) ==
            0;
    final items = <ActionItem>[];

    if (enrollment == null) {
      if (canEnroll && MembershipShim.isMember(actingUser.roles)) {
        items.add(
          _item(
            'Request to Join',
            'enroll',
            () => _master.requestToJoin(),
            unfunded: unfunded,
          ),
        );
      }
    } else {
      switch (enrollment.status) {
        case EnrollmentStatus.invited:
          if (canEnroll) {
            items.add(
              _item(
                'Accept',
                'accept',
                () => _master.acceptInvite(),
                unfunded: unfunded,
              ),
            );
          }
          items.add(_item('Decline', 'decline', () => _master.declineInvite()));
        case EnrollmentStatus.accepted ||
            EnrollmentStatus.assigned ||
            EnrollmentStatus.assignedTrial:
          items.add(_item('Withdraw', 'withdraw', () => _master.withdraw()));
        case EnrollmentStatus.withdrawRequested:
          items.add(
            _item(
              'Cancel Withdraw',
              'cancel_withdraw',
              () => _master.cancelWithdrawRequest(),
            ),
          );
        case EnrollmentStatus.requested:
          items.add(const ActionItem(label: 'Requested'));
        case EnrollmentStatus.rejected ||
            EnrollmentStatus.declined ||
            EnrollmentStatus.withdrawn ||
            EnrollmentStatus.removed:
          break;
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return ActionGroup(actions: items, inlineLimit: items.length);
  }

  ActionItem _item(
    String label,
    String key,
    Future<void> Function() run, {
    bool unfunded = false,
  }) {
    return ActionItem(
      label: label,
      loading: _running == key,
      onPressed: _running != null || unfunded ? null : () => _run(key, run),
      reason: unfunded
          ? (_) => CreditChip(username: _username, credits: 0)
          : null,
    );
  }

  ClMyEnrollmentsMasterNotifier get _master => ref.read(
    clMyEnrollmentsMasterProvider(
      (username: _username, eventId: _eventId),
    ).notifier,
  );

  Future<void> _run(String key, Future<void> Function() run) async {
    setState(() => _running = key);
    try {
      await run();
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(mapEnrollmentMutationError(e)),
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
      if (mounted) setState(() => _running = null);
    }
  }
}
