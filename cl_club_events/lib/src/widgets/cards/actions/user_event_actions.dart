import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../utils/event_write_error_message.dart';

/// Resolves member-perspective actions for a single event row.
///
/// Mirrors the legacy `EnrollmentActionButtons`: actions are derived from
/// the user's enrollment status (and the event's join-side gate).
///
/// | enrollment.status        | actions                           |
/// |--------------------------|-----------------------------------|
/// | none (and canEnroll)     | `[Request to Join]`               |
/// | `invited`                | `[Accept, ⋮ Decline]`             |
/// | `requested`              | `[Cancel Request]`                |
/// | `withdrawRequested`      | `[Cancel Withdraw]`               |
/// | `accepted`/`assigned`/   | `[Withdraw]`                      |
/// | `assignedTrial`          |                                   |
/// | other (terminal)         | (none)                            |
class UserEventActions extends ConsumerStatefulWidget {
  const UserEventActions({
    required this.username,
    required this.event,
    required this.builder,
    super.key,
  });

  final String username;
  final Event event;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`). Empty when the acting user
  /// has no applicable action for their enrollment status.
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<UserEventActions> createState() => UserEventActionsState();
}

class UserEventActionsState extends ConsumerState<UserEventActions> {
  String? _running;

  @override
  Widget build(BuildContext context) {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final key = (username: widget.username, eventId: widget.event.id);
    final enrollment = ref.watch(clMyEnrollmentProvider(key)).valueOrNull;

    // Member self-service stays self-service: staff viewing another
    // member's events get no member actions (club_core#127).
    final actions = actingUser == null || actingUser.username != widget.username
        ? const <ActionItem>[]
        : _resolve(actingUser, enrollment);
    return widget.builder(context, actions);
  }

  /// Credit the member can spend on this programme when that decides
  /// whether they may accept or ask to join (club_core#97): null — nothing
  /// greyed — for a camp or one-off, with credit off, or while unknown.
  int? usableCredit(Enrollment? enrollment) {
    if (widget.event.type != EventType.programme) return null;
    return ref.watch(
      clCreditUsableForEventProvider((
        username: widget.username,
        eventId: widget.event.id,
        trial: enrollment?.isTrial ?? false,
      )),
    );
  }

  List<ActionItem> _resolve(UserPrivate acting, Enrollment? enrollment) {
    final unfunded = usableCredit(enrollment) == 0;
    if (enrollment == null) {
      if (!MembershipShim.isMember(acting.roles)) return const [];
      if (!canEnrollOnEvent(widget.event, acting)) return const [];
      return [
        _item(
          'Request to Join',
          _requestToJoin,
          key: 'enroll',
          unfunded: unfunded,
        ),
      ];
    }
    switch (enrollment.status) {
      case EnrollmentStatus.invited:
        return [
          _item('Accept', _acceptInvite, key: 'accept', unfunded: unfunded),
          _item('Decline', _declineInvite, destructive: true, key: 'decline'),
        ];
      case EnrollmentStatus.requested:
        return [
          _item('Cancel Request', _withdraw, key: 'cancel'),
        ];
      case EnrollmentStatus.withdrawRequested:
        return [
          _item('Cancel Withdraw', _cancelWithdraw, key: 'cancel_withdraw'),
        ];
      case EnrollmentStatus.accepted ||
          EnrollmentStatus.assigned ||
          EnrollmentStatus.assignedTrial:
        return [
          _item('Withdraw', _withdraw, destructive: true, key: 'withdraw'),
        ];
      case EnrollmentStatus.rejected ||
          EnrollmentStatus.declined ||
          EnrollmentStatus.withdrawn ||
          EnrollmentStatus.removed:
        return const [];
    }
  }

  /// An action; [unfunded] greys it out with a 🪙 0 chip beside it.
  ActionItem _item(
    String label,
    Future<void> Function() run, {
    required String key,
    bool destructive = false,
    bool unfunded = false,
  }) {
    return ActionItem(
      label: label,
      loading: _running == key,
      destructive: destructive,
      onPressed: _running != null || unfunded ? null : () => _wrap(key, run),
      reason: unfunded
          ? (_) => CreditChip(username: widget.username, credits: 0)
          : null,
    );
  }

  Future<void> _requestToJoin() =>
      ref.read(_enrollmentsMaster.notifier).requestToJoin();
  Future<void> _acceptInvite() =>
      ref.read(_enrollmentsMaster.notifier).acceptInvite();
  Future<void> _declineInvite() =>
      ref.read(_enrollmentsMaster.notifier).declineInvite();
  Future<void> _withdraw() => ref.read(_enrollmentsMaster.notifier).withdraw();
  Future<void> _cancelWithdraw() =>
      ref.read(_enrollmentsMaster.notifier).cancelWithdrawRequest();

  AutoDisposeFamilyAsyncNotifierProvider<
    ClMyEnrollmentsMasterNotifier,
    Enrollment,
    ClMyEnrollmentsKey
  >
  get _enrollmentsMaster => clMyEnrollmentsMasterProvider(
    (username: widget.username, eventId: widget.event.id),
  );

  Future<void> _wrap(String key, Future<void> Function() run) async {
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
