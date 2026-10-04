import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../models/stale_version_message.dart';
import '../../../utils/event_write_error_message.dart';
import 'cancel_reason_dialog.dart';
import 'manage_requests_dialog.dart';
import 'occurrence_reschedule_dialog.dart';

/// Resolves admin / coach / organizer actions for a single occurrence.
///
/// Window-based gating against `DateTime.now()`:
///
/// - `< start − 30min`, scheduled / rescheduled: `[Reschedule, ⋮ {Cancel`
///   `occurrence, Cancel series, Manage requests}]`
/// - `< start − 30min`, cancelled: `[Undo Cancel]`
/// - `start − 30min … start + 15d`: `[Attendance]` (both statuses)
/// - `> start + 15d`: no actions (edit window closed)
///
/// A `rescheduled` occurrence is still a live day, so it gets the same
/// management actions as a scheduled one — keyed by `originalStartTimeUtc` so a
/// repeat reschedule moves the existing override, never the original slot.
/// `completed` always renders no actions.
///
/// Attendance is offered to the event's staff (`canManageAttendance`); every
/// other action to its organizer or an admin only (`canManageEvent`), as the
/// server requires (club_core#146).
///
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`. The list is empty when the occurrence is outside
/// every actionable window or the acting user can't manage it.
class AdminOccurrenceActions extends ConsumerStatefulWidget {
  const AdminOccurrenceActions({
    required this.occurrence,
    required this.onMarkAttendance,
    required this.builder,
    super.key,
  });

  final Occurrence occurrence;
  final void Function(int eventId, DateTime occurrenceTimeUtc) onMarkAttendance;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`).
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<AdminOccurrenceActions> createState() =>
      AdminOccurrenceActionsState();
}

class AdminOccurrenceActionsState
    extends ConsumerState<AdminOccurrenceActions> {
  String? _running;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _resolve());
  }

  List<ActionItem> _resolve() {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final event = ref
        .watch(clEventsMasterProvider)
        .valueOrNull?[widget.occurrence.eventId];
    if (actingUser == null || event == null) return const [];

    final start = widget.occurrence.actualStartTimeUtc;
    final end = widget.occurrence.actualEndTimeUtc;
    final inSchedulingWindow = isInScheduleManagementWindow(start);
    final inAttendanceWindow = canMarkAttendanceNow(
      actingUser: actingUser,
      effectiveStartTimeUtc: start,
      effectiveEndTimeUtc: end,
    );

    if (inAttendanceWindow) {
      if (!canManageAttendance(event, actingUser)) return const [];
      return [
        ActionItem(
          label: 'Attendance',
          onPressed: () => widget.onMarkAttendance(
            widget.occurrence.eventId,
            widget.occurrence.originalStartTimeUtc,
          ),
        ),
      ];
    }

    if (!inSchedulingWindow) {
      // Past the edit window — server rejects further mutations.
      return const [];
    }

    // Reschedule, cancel, undo-cancel and request decisions are the
    // organizer's or an admin's; an assigned coach's tier is attendance
    // only (club_core#146).
    if (!canManageEvent(event, actingUser)) return const [];

    switch (widget.occurrence.status) {
      // A rescheduled occurrence is still a live, future day — it offers the
      // same management actions as a scheduled one (reschedule again, cancel,
      // manage requests). Every action keys by `originalStartTimeUtc`, the
      // occurrence's stable identity, so a repeat reschedule updates the
      // existing override's effective start rather than the original slot.
      case OccurrenceStatus.scheduled || OccurrenceStatus.rescheduled:
        return _scheduledActions();

      case OccurrenceStatus.cancelled:
        return [
          ActionItem(
            label: 'Undo Cancel',
            loading: _running == 'undo',
            onPressed: _running != null
                ? null
                : () => _runAction('undo', _undoCancel),
          ),
        ];

      case OccurrenceStatus.completed:
        return const [];
    }
  }

  List<ActionItem> _scheduledActions() {
    return [
      ActionItem(
        label: 'Reschedule',
        icon: LucideIcons.calendarClock,
        onPressed: _running == null ? _handleReschedule : null,
      ),
      ActionItem(
        label: 'Cancel this occurrence',
        icon: LucideIcons.calendarX,
        destructive: true,
        loading: _running == 'cancel-instance',
        onPressed: _running != null
            ? null
            : () => _runAction('cancel-instance', _cancelInstance),
      ),
      ActionItem(
        label: 'Cancel entire series',
        icon: LucideIcons.calendarOff,
        destructive: true,
        loading: _running == 'cancel-series',
        onPressed: _running != null
            ? null
            : () => _runAction('cancel-series', _cancelSeries),
      ),
      ActionItem(
        label: 'Manage requests',
        icon: LucideIcons.userCheck,
        loading: _running == 'requests',
        onPressed: _running != null
            ? null
            : () => _runAction('requests', handleManageRequests),
      ),
    ];
  }

  Future<void> _cancelInstance() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialog(),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    await ref
        .read(clEventsMasterProvider.notifier)
        .cancelOccurrence(
          widget.occurrence.eventId,
          widget.occurrence.originalStartTimeUtc,
          version: widget.occurrence.version,
          reason: reason,
        );
  }

  Future<void> _cancelSeries() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialog(),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    // Pass null reference — master forwards a now() default to the SDK
    // (the SDK signature still requires non-null; follow-up will make it
    // nullable so null flows end-to-end).
    await ref
        .read(clEventsMasterProvider.notifier)
        .cancelSeries(
          widget.occurrence.eventId,
          reason: reason,
          effectiveDateTimeUtc: widget.occurrence.originalStartTimeUtc,
        );
  }

  Future<void> _undoCancel() async {
    await ref
        .read(clEventsMasterProvider.notifier)
        .undoCancelOccurrence(
          widget.occurrence.eventId,
          widget.occurrence.originalStartTimeUtc,
          version: widget.occurrence.version,
        );
  }

  Future<void> _handleReschedule() async {
    final rescheduled = await showShadDialog<bool>(
      context: context,
      builder: (_) => OccurrenceRescheduleDialog(occurrence: widget.occurrence),
    );
    if (rescheduled == true && mounted) {
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Session rescheduled.')),
      );
    }
  }

  /// Public so widget tests can drive the action without opening the
  /// PopupMenuButton overlay (which is fragile in tests). The unit-test
  /// path is otherwise the same as the production path.
  Future<void> handleManageRequests() async {
    ref.invalidate(clEnrollmentsMasterProvider(widget.occurrence.eventId));
    final enrollments = await ref.read(
      clEnrollmentsMasterProvider(widget.occurrence.eventId).future,
    );
    final requesting = enrollments.entries
        .where((e) => e.value == EnrollmentStatus.requested)
        .map((e) => e.key)
        .toList();
    if (!mounted) return;
    if (requesting.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast(description: Text('No pending requests.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => ManageRequestsDialog(
        eventId: widget.occurrence.eventId,
        requestingUsers: requesting,
        onComplete: () {},
      ),
    );
  }

  Future<void> _runAction(
    String key,
    Future<void> Function() run,
  ) async {
    setState(() => _running = key);
    try {
      await run();
    } on StaleVersionException catch (e) {
      // The camp master has already reloaded the occurrences.
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(staleVersionMessage(e, subject: 'This session')),
        ),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(description: Text(e.message)),
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
}
