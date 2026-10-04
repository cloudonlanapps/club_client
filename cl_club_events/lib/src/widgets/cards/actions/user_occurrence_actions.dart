import 'package:cl_club_credits/cl_club_credits.dart' show CreditChip;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../utils/event_write_error_message.dart';

/// Resolves member-perspective actions for a single occurrence.
///
/// Watches enrollment and attendance state, plus the event itself for
/// enrol-side gating. The resolved action list never carries more than two
/// actions, so overflow `⋮` is unused on the member side.
///
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`.
class UserOccurrenceActions extends ConsumerStatefulWidget {
  const UserOccurrenceActions({
    required this.username,
    required this.occurrence,
    required this.builder,
    super.key,
  });

  /// Label of the action offered in place of the leave action when the
  /// member's attendance could not be read (club_core#139).
  static const String reloadLeaveLabel = 'Reload leave';

  final String username;
  final Occurrence occurrence;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`).
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<UserOccurrenceActions> createState() =>
      UserOccurrenceActionsState();
}

class UserOccurrenceActionsState extends ConsumerState<UserOccurrenceActions> {
  /// Identifies which action is currently mid-mutation. `null` when idle.
  String? _running;

  @override
  Widget build(BuildContext context) {
    // Member self-service stays self-service: staff viewing another
    // member's sessions get no member actions (club_core#127).
    final acting = ref.watch(authStateProvider).valueOrNull;
    if (acting == null || acting.username != widget.username) {
      return widget.builder(context, const <ActionItem>[]);
    }
    final enrollmentKey = (
      username: widget.username,
      eventId: widget.occurrence.eventId,
    );
    final attendanceKey = (
      username: widget.username,
      eventId: widget.occurrence.eventId,
      occurrenceTimeUtc: widget.occurrence.originalStartTimeUtc,
    );

    final enrollment = ref
        .watch(clMyEnrollmentProvider(enrollmentKey))
        .valueOrNull;
    final attendance = ref.watch(clMyAttendancesMasterProvider(attendanceKey));
    final events = ref
        .watch(clMyEventsMasterProvider(widget.username))
        .valueOrNull;
    final event = events
        ?.where((e) => e.id == widget.occurrence.eventId)
        .firstOrNull;

    final start = widget.occurrence.actualStartTimeUtc;
    final isFuture = DateTime.now().toUtc().isBefore(start);
    final canApplyLeave = isInLeaveApplicationWindow(start);

    final actions = _resolveActions(
      enrollment: enrollment,
      attendance: attendance,
      event: event,
      isFuture: isFuture,
      canApplyLeave: canApplyLeave,
    );

    return widget.builder(context, actions);
  }

  List<ActionItem> _resolveActions({
    required Enrollment? enrollment,
    required AsyncValue<AttendanceRecord?> attendance,
    required Event? event,
    required bool isFuture,
    required bool canApplyLeave,
  }) {
    if (enrollment == null) {
      if (!isFuture) return const [];
      if (event == null) return const [];
      final actingUser = ref.watch(authStateProvider).valueOrNull;
      if (actingUser == null ||
          !MembershipShim.isMember(actingUser.roles) ||
          !canEnrollOnEvent(event, actingUser)) {
        return const [];
      }
      return [
        _buildAction(
          key: 'enroll',
          label: 'Enroll',
          unfunded: unfunded(event, null),
          run: () => ref
              .read(
                clMyEnrollmentsMasterProvider((
                  username: widget.username,
                  eventId: widget.occurrence.eventId,
                )).notifier,
              )
              .requestToJoin(),
          mapError: mapEnrollmentMutationError,
        ),
      ];
    }

    switch (enrollment.status) {
      case EnrollmentStatus.invited:
        return [
          _buildAction(
            key: 'accept',
            label: 'Accept',
            unfunded: unfunded(event, enrollment),
            run: () => ref
                .read(
                  clMyEnrollmentsMasterProvider((
                    username: widget.username,
                    eventId: widget.occurrence.eventId,
                  )).notifier,
                )
                .acceptInvite(),
            mapError: mapEnrollmentMutationError,
          ),
          _buildAction(
            key: 'decline',
            label: 'Decline',
            run: () => ref
                .read(
                  clMyEnrollmentsMasterProvider((
                    username: widget.username,
                    eventId: widget.occurrence.eventId,
                  )).notifier,
                )
                .declineInvite(),
            mapError: mapEnrollmentMutationError,
            destructive: true,
          ),
        ];

      case EnrollmentStatus.requested:
        return [
          _buildAction(
            key: 'cancel_request',
            label: 'Cancel Request',
            run: () => ref
                .read(
                  clMyEnrollmentsMasterProvider((
                    username: widget.username,
                    eventId: widget.occurrence.eventId,
                  )).notifier,
                )
                .withdraw(),
            mapError: mapEnrollmentMutationError,
          ),
        ];

      case EnrollmentStatus.withdrawRequested:
        return [
          _buildAction(
            key: 'cancel_withdraw',
            label: 'Cancel Withdraw',
            run: () => ref
                .read(
                  clMyEnrollmentsMasterProvider((
                    username: widget.username,
                    eventId: widget.occurrence.eventId,
                  )).notifier,
                )
                .cancelWithdrawRequest(),
            mapError: mapEnrollmentMutationError,
          ),
        ];

      case EnrollmentStatus.accepted ||
          EnrollmentStatus.assigned ||
          EnrollmentStatus.assignedTrial:
        if (!isFuture) return const [];
        final leaveAction = _leaveActionFor(
          attendance,
          canApplyLeave: canApplyLeave,
        );
        return [
          ?leaveAction,
          _buildAction(
            key: 'withdraw',
            label: 'Withdraw',
            run: () => ref
                .read(
                  clMyEnrollmentsMasterProvider((
                    username: widget.username,
                    eventId: widget.occurrence.eventId,
                  )).notifier,
                )
                .withdraw(),
            mapError: mapEnrollmentMutationError,
            destructive: true,
          ),
        ];

      case EnrollmentStatus.rejected ||
          EnrollmentStatus.declined ||
          EnrollmentStatus.withdrawn ||
          EnrollmentStatus.removed:
        return const [];
    }
  }

  /// The leave action for [attendanceAsync]: none while it first loads, a
  /// reload when it failed (club_core#139), else the record's own action.
  ActionItem? _leaveActionFor(
    AsyncValue<AttendanceRecord?> attendanceAsync, {
    required bool canApplyLeave,
  }) {
    if (attendanceAsync.hasError) return reloadLeaveAction(attendanceAsync);
    if (!attendanceAsync.hasValue) return null;
    final attendance = attendanceAsync.value;
    if (attendance == null) {
      if (!canApplyLeave) return null;
      return _buildAction(
        key: 'apply_leave',
        label: 'Apply Leave',
        run: () => ref
            .read(
              clMyAttendancesMasterProvider((
                username: widget.username,
                eventId: widget.occurrence.eventId,
                occurrenceTimeUtc: widget.occurrence.originalStartTimeUtc,
              )).notifier,
            )
            .requestLeave(),
        mapError: _mapLeaveError,
      );
    }
    switch (attendance.status) {
      case AttendanceStatus.onLeaveRequested:
        return _buildAction(
          key: 'cancel_leave_request',
          label: 'Cancel Leave Request',
          run: () => ref
              .read(
                clMyAttendancesMasterProvider((
                  username: widget.username,
                  eventId: widget.occurrence.eventId,
                  occurrenceTimeUtc: widget.occurrence.originalStartTimeUtc,
                )).notifier,
              )
              .cancelLeaveRequest(),
          mapError: _mapLeaveError,
        );
      case AttendanceStatus.onLeave:
        return _buildAction(
          key: 'cancel_leave',
          label: 'Cancel Leave',
          run: () => ref
              .read(
                clMyAttendancesMasterProvider((
                  username: widget.username,
                  eventId: widget.occurrence.eventId,
                  occurrenceTimeUtc: widget.occurrence.originalStartTimeUtc,
                )).notifier,
              )
              .cancelLeaveRequest(),
          mapError: _mapLeaveError,
        );
      case AttendanceStatus.present ||
          AttendanceStatus.absent ||
          AttendanceStatus.late:
        return null;
    }
  }

  /// Re-reads the member's attendance after a failed read; spins while the
  /// re-read is in flight.
  ActionItem reloadLeaveAction(AsyncValue<AttendanceRecord?> attendanceAsync) {
    final loading = attendanceAsync.isLoading;
    return ActionItem(
      label: UserOccurrenceActions.reloadLeaveLabel,
      loading: loading,
      onPressed: loading || _running != null
          ? null
          : () => ref
                .read(
                  clMyAttendancesMasterProvider((
                    username: widget.username,
                    eventId: widget.occurrence.eventId,
                    occurrenceTimeUtc: widget.occurrence.originalStartTimeUtc,
                  )).notifier,
                )
                .reload(),
    );
  }

  /// An action; [unfunded] greys it out with a 🪙 0 chip beside it
  /// (club_core#97).
  ActionItem _buildAction({
    required String key,
    required String label,
    required Future<void> Function() run,
    required String Function(ServerException) mapError,
    bool destructive = false,
    bool unfunded = false,
  }) {
    final busy = _running != null;
    return ActionItem(
      label: label,
      loading: _running == key,
      destructive: destructive,
      onPressed: busy || unfunded ? null : () => _runAction(key, run, mapError),
      reason: unfunded
          ? (_) => CreditChip(username: widget.username, credits: 0)
          : null,
    );
  }

  /// Whether the member lacks usable credit for this programme, so
  /// enrolling or accepting is greyed out (club_core#97). False for a camp
  /// or one-off, with credit off, or while unknown.
  bool unfunded(Event? event, Enrollment? enrollment) {
    if (event == null || event.type != EventType.programme) return false;
    return ref.watch(
          clCreditUsableForEventProvider((
            username: widget.username,
            eventId: event.id,
            trial: enrollment?.isTrial ?? false,
          )),
        ) ==
        0;
  }

  Future<void> _runAction(
    String key,
    Future<void> Function() run,
    String Function(ServerException) mapError,
  ) async {
    setState(() => _running = key);
    try {
      await run();
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(mapError(e))),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(eventWriteErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  String _mapLeaveError(ServerException e) => switch (e.code) {
    SdkErrorCode.leaveWindowClosed => 'The leave request window has closed.',
    SdkErrorCode.leaveAlreadyDeclared =>
      'A leave request already exists for this session.',
    SdkErrorCode.attendanceNotYetOpen =>
      'Attendance has not yet opened for this occurrence.',
    _ => e.message,
  };
}
