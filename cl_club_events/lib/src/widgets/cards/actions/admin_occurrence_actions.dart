import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../models/admin_occurrence_action.dart';
import '../../../models/stale_version_message.dart';
import '../../../utils/admin_occurrence_actions_for.dart';
import '../../../utils/event_write_error_message.dart';
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
        itemFor(action),
    ];
  }

  /// The [ActionItem] of [action], wired to its call.
  ActionItem itemFor(AdminOccurrenceAction action) => switch (action) {
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
      onPressed: running != null ? null : () => runAction('undo', undoCancel),
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
