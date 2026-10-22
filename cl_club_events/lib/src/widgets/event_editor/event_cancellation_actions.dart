import 'package:cl_member_auth/cl_member_auth.dart' show canManageEvent;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        clEventsMasterProvider,
        clSingleOccurrenceProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog;

import '../../models/event_cancellation_messages.dart';
import '../../models/event_management_action.dart';
import '../../utils/event_cancellation_error.dart';
import '../../utils/one_off_time_rules.dart';
import '../../utils/save_confirming_schedule_clash.dart';
import 'event_cancellation_dialog.dart';

/// Resolves the Event Management actions that call an event off and take
/// that back (club_client#40), for an admin or the event's organizer:
///
/// | Type | Action | Shown when |
/// |---|---|---|
/// | Camp | Cancel camp | not cancelled (no cutoff) |
/// | Camp | Undo cancel | cancelled |
/// | One-off | Call off | not cancelled, before `start − 30min` |
/// | One-off | Reinstate | cancelled, until its start |
///
/// A programme has none, nor has an archived event. A one-off's state and
/// the version its calls send are those of its single occurrence, so its
/// actions appear once that occurrence has loaded. The one-off's time rules
/// are the server's (a super-admin may call one off any time), shared with
/// the occurrence card ([canCallOffOneOffAt],
/// [canReinstateOneOffAt]; club_client#187).
///
/// Hosts the resolved actions and hands them to [builder].
class EventCancellationActions extends ConsumerStatefulWidget {
  const EventCancellationActions({
    required this.event,
    required this.currentUser,
    required this.builder,
    super.key,
  });

  final Event event;

  /// The viewer; only an admin or the event's organizer gets the actions.
  final UserPrivate currentUser;

  /// Receives the resolved actions and returns the host widget.
  final Widget Function(
    BuildContext context,
    List<EventManagementAction> actions,
  )
  builder;

  @override
  ConsumerState<EventCancellationActions> createState() =>
      EventCancellationActionsState();
}

class EventCancellationActionsState
    extends ConsumerState<EventCancellationActions> {
  bool isRunning = false;

  /// Opens the reason dialog; toasts [done] once the server accepted it.
  Future<void> handleCallOff({
    required String done,
    int? occurrenceVersion,
  }) async {
    final accepted = await showShadDialog<bool>(
      context: context,
      builder: (_) => EventCancellationDialog(
        event: widget.event,
        occurrenceVersion: occurrenceVersion,
      ),
    );
    if (accepted != true || !mounted) return;
    ShadToaster.of(context).show(ShadToast(description: Text(done)));
  }

  /// Asks [question] under [title]; on yes runs [change] and toasts [done],
  /// or a readable refusal ([failed] when there is no better one).
  ///
  /// A [change] the server refuses as a schedule clash (a reinstate) asks
  /// whether to save it anyway and runs it again with `acceptConflicts`
  /// ([saveConfirmingScheduleClash]); Cancel changes nothing.
  Future<void> handleTakeBack({
    required String title,
    required String question,
    required String confirmLabel,
    required Future<void> Function(
      ClEventsMasterNotifier notifier, {
      required bool acceptConflicts,
    })
    change,
    required String done,
    required String failed,
  }) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: title,
      message: question,
      confirmLabel: confirmLabel,
      cancelLabel: EventCancellationMessages.back,
    );
    if (!confirmed || !mounted) return;
    final toaster = ShadToaster.of(context);
    setState(() => isRunning = true);
    try {
      final notifier = ref.read(clEventsMasterProvider.notifier);
      final saved = await saveConfirmingScheduleClash(
        context,
        ({required acceptConflicts}) =>
            change(notifier, acceptConflicts: acceptConflicts),
      );
      if (saved) toaster.show(ShadToast(description: Text(done)));
    } on Object catch (e, st) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            eventCancellationErrorMessage(e, stackTrace: st, fallback: failed),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isRunning = false);
    }
  }

  List<EventManagementAction> campActions(Event event) => [
    if (event.untilTimeUtc == null)
      (
        label: EventCancellationMessages.cancelCamp,
        onPressed: () =>
            handleCallOff(done: EventCancellationMessages.campCancelled),
      )
    else
      (
        label: EventCancellationMessages.undoCancel,
        onPressed: () => handleTakeBack(
          title: EventCancellationMessages.undoCancelTitle,
          question: EventCancellationMessages.undoCancelConfirm(event.title),
          confirmLabel: EventCancellationMessages.undoCancel,
          // Undoing a camp's cancel is not checked for clashes.
          change: (notifier, {required acceptConflicts}) =>
              notifier.undoCancelSeries(event.id, version: event.version),
          done: EventCancellationMessages.cancelUndone,
          failed: EventCancellationMessages.undoCancelFailed,
        ),
      ),
  ];

  List<EventManagementAction> oneOffActions(Event event) {
    final occurrence = ref
        .watch(
          clSingleOccurrenceProvider(
            (eventId: event.id, occurrenceTimeUtc: event.startTimeUtc),
          ),
        )
        .valueOrNull;
    if (occurrence == null) return const [];
    final cancelled = occurrence.status == OccurrenceStatus.cancelled;
    return [
      if (cancelled && canReinstateOneOffAt(occurrence.originalStartTimeUtc))
        (
          label: EventCancellationMessages.reinstate,
          onPressed: () => handleTakeBack(
            title: EventCancellationMessages.reinstateTitle,
            question: EventCancellationMessages.reinstateConfirm(event.title),
            confirmLabel: EventCancellationMessages.reinstate,
            change: (notifier, {required acceptConflicts}) =>
                notifier.reinstate(
                  event.id,
                  version: occurrence.version,
                  acceptConflicts: acceptConflicts,
                ),
            done: EventCancellationMessages.reinstated,
            failed: EventCancellationMessages.reinstateFailed,
          ),
        ),
      if (!cancelled &&
          canCallOffOneOffAt(
            occurrence.actualStartTimeUtc,
            widget.currentUser,
          ))
        (
          label: EventCancellationMessages.callOff,
          onPressed: () => handleCallOff(
            done: EventCancellationMessages.calledOff,
            occurrenceVersion: occurrence.version,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final offered = event.isActive && canManageEvent(event, widget.currentUser);
    final actions = !offered
        ? const <EventManagementAction>[]
        : switch (event.type) {
            EventType.camp => campActions(event),
            EventType.oneOff => oneOffActions(event),
            EventType.programme => const <EventManagementAction>[],
          };
    return widget.builder(context, [
      for (final action in actions)
        (label: action.label, onPressed: isRunning ? null : action.onPressed),
    ]);
  }
}
