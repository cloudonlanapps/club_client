import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../models/admin_occurrence_action.dart';
import '../../../models/attendance_progress.dart';
import '../../../models/event_cancellation_messages.dart';
import '../../../models/programme_schedule_form_helpers.dart';
import '../../../models/stale_version_message.dart';
import '../../../utils/admin_occurrence_actions_for.dart';
import '../../../utils/event_cancellation_error.dart';
import '../../../utils/event_write_error_message.dart';
import '../../../utils/programme_end_date.dart';
import '../../../utils/programme_end_date_messages.dart';
import '../../../utils/read_programme_schedules.dart';
import '../../../utils/save_confirming_schedule_clash.dart';
import '../../attendance_progress_icon.dart';
import '../../event_editor/event_cancellation_dialog.dart';
import '../../event_editor/programme_end_date_dialog.dart';
import '../../requests/requests_sheet.dart';
import '../../requests_mark_icon.dart';
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

/// The label of [AdminOccurrenceAction.manageRequests].
const String manageRequestsLabel = 'Manage requests';

/// The label of [AdminOccurrenceAction.endProgramme].
const String endProgrammeLabel = 'End programme from here';

/// The label of [AdminOccurrenceAction.clearEndDate].
const String clearEndDateLabel = ProgrammeEndDateDialog.clearLabel;

class AdminOccurrenceActionsState
    extends ConsumerState<AdminOccurrenceActions> {
  /// The key of the action in flight, or `null`.
  String? _running;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _resolve());
  }

  /// The actions offered now, as [ActionItem]s.
  List<ActionItem> _resolve() {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final event = ref
        .watch(clEventsMasterProvider)
        .valueOrNull?[widget.occurrence.eventId];
    if (actingUser == null || event == null) return const [];
    return [
      for (final action in leadWithRequests(
        adminOccurrenceActionsFor(
          occurrence: widget.occurrence,
          event: event,
          actingUser: actingUser,
        ),
        widget.occurrence,
      ))
        _itemFor(action, event, actingUser),
    ];
  }

  /// The [ActionItem] of [action] on an occurrence of [event], wired to its
  /// call.
  ActionItem _itemFor(
    AdminOccurrenceAction action,
    Event event,
    UserPrivate actingUser,
  ) => switch (action) {
    AdminOccurrenceAction.attendance => _attendanceItem(actingUser),
    AdminOccurrenceAction.reschedule => ActionItem(
      label: 'Reschedule',
      icon: LucideIcons.calendarClock,
      onPressed: _running == null ? _handleReschedule : null,
    ),
    AdminOccurrenceAction.cancelOccurrence => ActionItem(
      label: 'Cancel this occurrence',
      icon: LucideIcons.calendarX,
      destructive: true,
      loading: _running == 'cancel-instance',
      onPressed: _running != null
          ? null
          : () => _runAction(
              'cancel-instance',
              () => _cancelInstance(event),
            ),
    ),
    AdminOccurrenceAction.cancelSeries => ActionItem(
      label: 'Cancel entire series',
      icon: LucideIcons.calendarOff,
      destructive: true,
      loading: _running == 'cancel-series',
      onPressed: _running != null
          ? null
          : () => _runAction('cancel-series', () => _cancelSeries(event)),
    ),
    AdminOccurrenceAction.endProgramme => ActionItem(
      label: endProgrammeLabel,
      icon: LucideIcons.calendarOff,
      destructive: true,
      loading: _running == 'end-programme',
      onPressed: _running != null
          ? null
          : () => _runAction('end-programme', () => _endProgramme(event)),
    ),
    AdminOccurrenceAction.clearEndDate => ActionItem(
      label: clearEndDateLabel,
      icon: LucideIcons.calendarRange,
      loading: _running == 'clear-end',
      onPressed: _running != null
          ? null
          : () => _runAction('clear-end', () => _clearEndDate(event)),
    ),
    AdminOccurrenceAction.callOff => ActionItem(
      label: EventCancellationMessages.callOff,
      icon: LucideIcons.calendarX,
      destructive: true,
      loading: _running == 'call-off',
      onPressed: _running != null
          ? null
          : () => _runAction('call-off', () => _callOff(event)),
    ),
    AdminOccurrenceAction.manageRequests => ActionItem(
      label: manageRequestsLabel,
      icon: LucideIcons.userCheck,
      leading: RequestsMarkIcon.buttonMark(widget.occurrence),
      loading: _running == 'requests',
      onPressed: _running != null
          ? null
          : () => _runAction('requests', _handleManageRequests),
    ),
    AdminOccurrenceAction.undoCancel => ActionItem(
      label: 'Undo Cancel',
      loading: _running == 'undo',
      onPressed: _running != null
          ? null
          : () => _runAction('undo', _undoCancel),
    ),
    AdminOccurrenceAction.reinstate => ActionItem(
      label: EventCancellationMessages.reinstate,
      loading: _running == 'reinstate',
      onPressed: _running != null
          ? null
          : () => _runAction('reinstate', () => _reinstate(event)),
    ),
  };

  /// Attendance, with how far it is taken; closed, "No members enrolled"
  /// beside it, when nobody is enrolled in the session and the viewer is
  /// not a super-admin (club_client#414).
  ActionItem _attendanceItem(UserPrivate actingUser) {
    final closed = attendanceClosedForNoMembers(widget.occurrence, actingUser);
    return ActionItem(
      label: 'Attendance',
      leading: AttendanceProgressIcon.buttonMark(widget.occurrence),
      onPressed: closed
          ? null
          : () => widget.onMarkAttendance(
              widget.occurrence.eventId,
              widget.occurrence.originalStartTimeUtc,
            ),
      reason: closed
          ? (context) {
              final theme = ShadTheme.of(context);
              return Text(
                noMembersEnrolledLabel,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              );
            }
          : null,
    );
  }

  /// Cancels this session of [event] alone, in the cancellation dialog,
  /// which asks for the reason and saves while it is open (club_client#213).
  ///
  /// A session whose register is open, which only a super-admin is offered,
  /// is first confirmed: cancelling it deletes its marks and refunds its
  /// credit, with no notification (club_client#312).
  Future<void> _cancelInstance(Event event) async {
    if (hasOpenRegister(widget.occurrence)) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: EventCancellationMessages.cancelOpenRegisterTitle,
        message: EventCancellationMessages.cancelOpenRegisterConfirm,
        confirmLabel: EventCancellationMessages.cancelOpenRegisterContinue,
        cancelLabel: EventCancellationMessages.back,
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    await _openCancellation(
      EventCancellationDialog.occurrence(
        event: event,
        occurrence: widget.occurrence,
      ),
      done: EventCancellationMessages.occurrenceCancelled,
    );
  }

  /// Cancels the camp [event] from this session on, in the cancellation
  /// dialog (club_client#213).
  Future<void> _cancelSeries(Event event) => _openCancellation(
    EventCancellationDialog.seriesFrom(
      event: event,
      occurrence: widget.occurrence,
    ),
    done: EventCancellationMessages.campCancelled,
  );

  /// Opens [dialog]; toasts [done] once the server accepted the change.
  Future<void> _openCancellation(
    EventCancellationDialog dialog, {
    required String done,
  }) async {
    final accepted = await showShadDialog<bool>(
      context: context,
      builder: (_) => dialog,
    );
    if (accepted != true || !mounted) return;
    ShadToaster.of(context).show(ShadToast(description: Text(done)));
  }

  /// Opens Adjust end date for the programme [event], on the last day
  /// before this occurrence's: Save terminates it there, or moves the end
  /// it has.
  Future<void> _endProgramme(Event event) async {
    final schedules = await readProgrammeSchedules(ref, event.id);
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

  /// Asks to clear the programme [event]'s end date, naming the day it ends
  /// on now; on yes it runs indefinitely (club_client#184).
  Future<void> _clearEndDate(Event event) async {
    final schedules = await readProgrammeSchedules(ref, event.id);
    final lastDay = programmeEndDay(event, schedules: schedules);
    if (lastDay == null || !mounted) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: clearEndDateLabel,
      message: programmeClearEndConfirm(lastDay),
      confirmLabel: clearEndDateLabel,
    );
    if (!confirmed || !mounted) return;
    final toaster = ShadToaster.of(context);
    try {
      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: null,
        reason: '',
        notifier: ref.read(clEventsMasterProvider.notifier),
        schedules: schedules,
      );
      toaster.show(
        const ShadToast(description: Text(programmeEndDateClearedMessage)),
      );
    } on StaleVersionException catch (e) {
      // The master has already reloaded the programme.
      toaster.show(
        ShadToast.destructive(
          description: Text(staleVersionMessage(e, subject: 'This programme')),
        ),
      );
    } on Object catch (e) {
      toaster.show(
        ShadToast.destructive(description: Text(programmeEndDateFailureOf(e))),
      );
    }
  }

  /// Calls the one-off [event] off (`drop`) in the event page's Call off
  /// dialog, which saves while it is open and shows what the server
  /// refuses; toasts once the server accepted it (club_client#183).
  Future<void> _callOff(Event event) => _openCancellation(
    EventCancellationDialog(
      event: event,
      occurrenceVersion: widget.occurrence.version,
    ),
    done: EventCancellationMessages.calledOff,
  );

  /// Reinstates the one-off [event] once confirmed (club_client#183, #278).
  Future<void> _reinstate(Event event) async {
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
      final notifier = ref.read(clEventsMasterProvider.notifier);
      final saved = await saveConfirmingScheduleClash(
        context,
        ({required acceptConflicts}) => notifier.reinstate(
          event.id,
          version: widget.occurrence.version,
          acceptConflicts: acceptConflicts,
        ),
      );
      if (!saved) return;
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

  /// Opens the Requests sheet of this session (club_client#437).
  Future<void> _handleManageRequests() =>
      showRequestsSheet(context, ref, occurrence: widget.occurrence);

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
