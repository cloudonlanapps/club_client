import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../models/admin_occurrence_action.dart';
import '../../../models/event_cancellation_messages.dart';
import '../../../models/stale_version_message.dart';
import '../../../utils/admin_occurrence_actions_for.dart';
import '../../../utils/event_cancellation_error.dart';
import '../../../utils/event_write_error_message.dart';
import '../../../utils/programme_end_date.dart';
import '../../event_editor/event_cancellation_dialog.dart';
import '../../event_editor/programme_end_date_dialog.dart';
import 'cancel_reason_dialog.dart';
import 'manage_requests_dialog.dart';
import 'occurrence_reschedule_dialog.dart';

/// The staff actions of a single occurrence, as [adminOccurrenceActionsFor]
/// resolves them for the acting user, each wired to its call.
///
/// Every action keys by `originalStartTimeUtc`, the occurrence's stable
/// identity, so a repeat reschedule moves the existing override, never the
/// original slot.
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

/// The label of [AdminOccurrenceAction.endProgramme].
const String endProgrammeLabel = 'End programme from here';

class AdminOccurrenceActionsState
    extends ConsumerState<AdminOccurrenceActions> {
  /// The key of the action in flight, or `null`.
  String? running;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, resolve());
  }

  /// The actions offered now, as [ActionItem]s.
  List<ActionItem> resolve() {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final event = ref
        .watch(clEventsMasterProvider)
        .valueOrNull?[widget.occurrence.eventId];
    if (actingUser == null || event == null) return const [];
    return [
      for (final action in adminOccurrenceActionsFor(
        occurrence: widget.occurrence,
        event: event,
        actingUser: actingUser,
      ))
        itemFor(action, event),
    ];
  }

  /// The [ActionItem] of [action] on an occurrence of [event], wired to its
  /// call.
  ActionItem itemFor(AdminOccurrenceAction action, Event event) =>
      switch (action) {
        AdminOccurrenceAction.attendance => ActionItem(
          label: 'Attendance',
          onPressed: () => widget.onMarkAttendance(
            widget.occurrence.eventId,
            widget.occurrence.originalStartTimeUtc,
          ),
        ),
        AdminOccurrenceAction.reschedule => ActionItem(
          label: 'Reschedule',
          icon: LucideIcons.calendarClock,
          onPressed: running == null ? handleReschedule : null,
        ),
        AdminOccurrenceAction.cancelOccurrence => ActionItem(
          label: 'Cancel this occurrence',
          icon: LucideIcons.calendarX,
          destructive: true,
          loading: running == 'cancel-instance',
          onPressed: running != null
              ? null
              : () => runAction('cancel-instance', cancelInstance),
        ),
        AdminOccurrenceAction.cancelSeries => ActionItem(
          label: 'Cancel entire series',
          icon: LucideIcons.calendarOff,
          destructive: true,
          loading: running == 'cancel-series',
          onPressed: running != null
              ? null
              : () => runAction('cancel-series', cancelSeries),
        ),
        AdminOccurrenceAction.endProgramme => ActionItem(
          label: endProgrammeLabel,
          icon: LucideIcons.calendarOff,
          destructive: true,
          loading: running == 'end-programme',
          onPressed: running != null
              ? null
              : () => runAction('end-programme', () => endProgramme(event)),
        ),
        AdminOccurrenceAction.callOff => ActionItem(
          label: EventCancellationMessages.callOff,
          icon: LucideIcons.calendarX,
          destructive: true,
          loading: running == 'call-off',
          onPressed: running != null
              ? null
              : () => runAction('call-off', () => callOff(event)),
        ),
        AdminOccurrenceAction.manageRequests => ActionItem(
          label: 'Manage requests',
          icon: LucideIcons.userCheck,
          loading: running == 'requests',
          onPressed: running != null
              ? null
              : () => runAction('requests', handleManageRequests),
        ),
        AdminOccurrenceAction.undoCancel => ActionItem(
          label: 'Undo Cancel',
          loading: running == 'undo',
          onPressed: running != null
              ? null
              : () => runAction('undo', undoCancel),
        ),
        AdminOccurrenceAction.reinstate => ActionItem(
          label: EventCancellationMessages.reinstate,
          loading: running == 'reinstate',
          onPressed: running != null
              ? null
              : () => runAction('reinstate', () => reinstate(event)),
        ),
      };

  Future<void> cancelInstance() async {
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

  Future<void> cancelSeries() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelReasonDialog(),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    // Pass null reference — master forwards a now() default to the SDK
    // (the SDK signature still requires non-null; follow-up will make it
    // nullable so null flows end-to-end).
    // No version is passed: the master sends the one it holds for the event
    // this session belongs to (club_client#123).
    try {
      await ref
          .read(clEventsMasterProvider.notifier)
          .cancelSeries(
            widget.occurrence.eventId,
            reason: reason,
            effectiveDateTimeUtc: widget.occurrence.originalStartTimeUtc,
          );
    } on StaleVersionException catch (e) {
      // The master has already reloaded the event and its sessions.
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(staleVersionMessage(e, subject: 'This event')),
        ),
      );
    }
  }

  /// Opens Adjust end date for the programme [event], on the last day
  /// before this occurrence's: Save terminates it there, or moves the end
  /// it has.
  Future<void> endProgramme(Event event) async {
    List<EventSchedule>? schedules;
    try {
      schedules = await ref.read(clEventSchedulesProvider(event.id).future);
    } on Object catch (_) {
      // The event then stands for its current schedule.
      schedules = null;
    }
    if (!mounted) return;
    await showShadDialog<void>(
      context: context,
      builder: (_) => ProgrammeEndDateDialog(
        event: event,
        schedules: schedules,
        proposedLastDay: programmeLastDayBeforeSession(
          event,
          widget.occurrence.originalStartTimeUtc,
          schedules: schedules,
        ),
      ),
    );
  }

  /// Calls the one-off [event] off (`drop`) in the event page's Call off
  /// dialog, which saves while it is open and shows what the server
  /// refuses; toasts once the server accepted it (club_client#183).
  Future<void> callOff(Event event) async {
    final accepted = await showShadDialog<bool>(
      context: context,
      builder: (_) => EventCancellationDialog(
        event: event,
        occurrenceVersion: widget.occurrence.version,
      ),
    );
    if (accepted != true || !mounted) return;
    ShadToaster.of(context).show(
      const ShadToast(description: Text(EventCancellationMessages.calledOff)),
    );
  }

  /// Reinstates the called-off one-off [event] after the event page's
  /// confirmation, with its messages (club_client#183).
  Future<void> reinstate(Event event) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: EventCancellationMessages.reinstateTitle,
      message: EventCancellationMessages.reinstateConfirm(event.title),
      confirmLabel: EventCancellationMessages.reinstate,
      cancelLabel: EventCancellationMessages.back,
    );
    if (!confirmed || !mounted) return;
    final toaster = ShadToaster.of(context);
    try {
      await ref
          .read(clEventsMasterProvider.notifier)
          .reinstate(event.id, version: widget.occurrence.version);
      toaster.show(
        const ShadToast(
          description: Text(EventCancellationMessages.reinstated),
        ),
      );
    } on Object catch (e, st) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            eventCancellationErrorMessage(
              e,
              stackTrace: st,
              fallback: EventCancellationMessages.reinstateFailed,
            ),
          ),
        ),
      );
    }
  }

  Future<void> undoCancel() async {
    await ref
        .read(clEventsMasterProvider.notifier)
        .undoCancelOccurrence(
          widget.occurrence.eventId,
          widget.occurrence.originalStartTimeUtc,
          version: widget.occurrence.version,
        );
  }

  Future<void> handleReschedule() async {
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

  Future<void> runAction(
    String key,
    Future<void> Function() run,
  ) async {
    setState(() => running = key);
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
      if (mounted) setState(() => running = null);
    }
  }
}
